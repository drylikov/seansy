#import "SEADataManager.h"

#import "LMAddress.h"
#import "LMGeocoder.h"
#import "NSDate+SEAHelpers.h"
#import "NSString+SEAHelpers.h"
#import "SEABackdrop.h"
#import "SEAConstants.h"
#import "SEALocationManager.h"
#import "AYMacros.h"
#import "SEAMoviesFilter.h"
#import <AFNetworking/AFNetworking.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

NSInteger const kUTCTimeForNextUpdate = 4;
NSInteger const kNewDayStartHour = 3;

@interface SEADataManager ()

@property (nonatomic) AFHTTPRequestOperationManager *manager;
@property (nonatomic) BOOL fromCache;
@property (nonatomic) NSArray *cachedNews;
@property (nonatomic) NSArray *starredTheatresIds;
@property (atomic) RACSignal *dataSignal;
@property (nonatomic) NSDate *today;
@property (nonatomic) NSDate *tomorrow;
@property (nonatomic) NSDateFormatter *timeFormatter;
@property (nonatomic) NSDate *timeStartDate;

@end

@implementation SEADataManager

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://seansy.kz/api/"]];
  self.manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions);
  self.dateFormatter = [NSDateFormatter new];
  self.dateFormatter.dateFormat = @"dd'-'MM'-'yyyy";
  self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Almaty"];
  self.timeFormatter = [NSDateFormatter new];
  self.timeFormatter.dateFormat = @"HH:mm";
  self.timeStartDate = [self.timeFormatter dateFromString:@"00:00"];
  self.selectedDayIndex = SEAShowtimesDateToday;

  return self;
}

+ (SEADataManager *)sharedInstance {
  static SEADataManager *sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    sharedInstance = [SEADataManager new];
  });
  return sharedInstance;
}

#pragma mark Setters & getters

- (NSDate *)today {
  if (_today) {
    return _today;
  }
  NSTimeInterval serverDateOffset = [NSTimeZone timeZoneWithName:@"Asia/Almaty"].secondsFromGMT;
  NSTimeInterval localDateOffset = [NSTimeZone defaultTimeZone].secondsFromGMT;
  NSDate *serverDate = [[NSDate date] dateByAddingTimeInterval:serverDateOffset - localDateOffset - kNewDayStartHour * 60 * 60];
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *components = [calendar components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:serverDate];
  _today = [calendar dateFromComponents:components];
  return _today;
}

- (NSDate *)tomorrow {
  return [self.today dateByAddingTimeInterval:24 * 60 * 60];
}

- (void)setSelectedDayIndex:(SEAShowtimesDate)selectedDayIndex {
  _selectedDayIndex = selectedDayIndex;
  switch (selectedDayIndex) {
    case SEAShowtimesDateToday:
      _selectedDate = self.today;
      break;
    case SEAShowtimesDateTomorrow:
      _selectedDate = self.tomorrow;
      break;
    default:
      break;
  }
}

#pragma mark Loading

- (void)setActivityIndicatorVisible:(BOOL)visible {
#ifndef TARGET_IS_EXTENSION
  [UIApplication sharedApplication].networkActivityIndicatorVisible = visible;
#endif
}

- (RACSignal *)loadDataFromCache:(BOOL)fromCache {
  if (self.dataSignal) {
    return self.dataSignal;
  }
  self.fromCache = fromCache;
  self.dataSignal = [[[[RACSignal merge:@[
                          [self loadMovies:kNowPlayingMoviesQuery],
                          [self loadMovies:kComingSoonMoviesQuery],
                          [self loadTheatres],
                          [self loadNews]
                        ]] replayLazily] initially:^{
    [self setActivityIndicatorVisible:YES];
  }] finally:^{
    self.loaded = YES;
    self.dataSignal = nil;
    [self setActivityIndicatorVisible:NO];
  }];
  return self.dataSignal;
}

- (RACSignal *)reloadNews {
  if (!self.loaded) {
    return [RACSignal empty];
  }
  self.cachedNews = self.news;
  self.news = nil;
  return [[[self loadNews] initially:^{
    [self setActivityIndicatorVisible:YES];
  }] finally:^{
    [self setActivityIndicatorVisible:NO];
  }];
}

- (RACSignal *)loadMovies:(NSString *)query {
  if ([query isEqualToString:kNowPlayingMoviesQuery]) {
    if (self.fromCache) {
      [self restoreNowPlayingMovies];
    }
    if (self.nowPlayingMovies && self.nowPlayingMovies.count > 0) {
      [self restoreShowtimes];
      for (SEAMovie *movie in self.nowPlayingMovies) {
        [movie processShowtimes];
      }
      DDLogInfo(@"✓ %@ now playing movies loaded from cache", @(self.nowPlayingMovies.count));
      NSArray *sortedMovies = [SEADataManager moviesSortedByShowtimes:self.nowPlayingMovies];
      self.featuredMovies = [sortedMovies subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)5, sortedMovies.count))];
      [[NSNotificationCenter defaultCenter] postNotificationName:kNowPlayingMoviesLoadedNotification object:nil];
      return [RACSignal return :self.nowPlayingMovies];
    }
  } else {
    if (self.fromCache) {
      [self restoreComingSoonMovies];
    }
    if (self.comingSoonMovies && self.comingSoonMovies.count > 0) {
      DDLogInfo(@"✓ %@ coming soon movies loaded from cache", @(self.comingSoonMovies.count));
      [[NSNotificationCenter defaultCenter] postNotificationName:kComingSoonMoviesLoadedNotification object:nil];
      return [RACSignal return :self.comingSoonMovies];
    }
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if ([query isEqualToString:kNowPlayingMoviesQuery]) {
      self.nowPlayingMovies = [NSMutableArray new];
    } else {
      self.comingSoonMovies = [NSMutableArray new];
    }
    [self.manager GET:query parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
      if ([responseObject isKindOfClass:[NSArray class]]) {
        NSArray *moviesDictionaries = (NSArray *)responseObject;
        for (id movieObject in moviesDictionaries) {
          if ([movieObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *movieDictionary = (NSDictionary *)movieObject;
            SEAMovie *movie = [[SEAMovie alloc] initWithDictionary:movieDictionary];
            if ([query isEqualToString:kNowPlayingMoviesQuery]) {
              [self.nowPlayingMovies addObject:movie];
            } else if (![movie isPlaying]) {
              [self.comingSoonMovies addObject:movie];
            }
          } else {
            [subscriber sendError:nil];
          }
        }
        if ([query isEqualToString:kNowPlayingMoviesQuery]) {
          [[self loadShowtimes] subscribe:subscriber];
        } else {
          self.comingSoonMovies = [[SEADataManager moviesSortedByDate:self.comingSoonMovies] mutableCopy];
          [self saveComingSoonMovies];
          DDLogInfo(@"✓ %@ coming soon movies loaded", @(self.comingSoonMovies.count));
          [[NSNotificationCenter defaultCenter] postNotificationName:kComingSoonMoviesLoadedNotification object:nil];
          [subscriber sendNext:self.comingSoonMovies];
          [subscriber sendCompleted];
        }
      } else {
        [subscriber sendError:nil];
      }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)loadShowtimes {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    self.showtimes = [NSMutableDictionary new];
    [self.manager GET:[kAllShowtimesQuery stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
      if ([responseObject isKindOfClass:[NSArray class]]) {
        NSArray *showtimesDictionaries = (NSArray *)responseObject;
        for (id showtimeObject in showtimesDictionaries) {
          if ([showtimeObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *showtimeDictionary = (NSDictionary *)showtimeObject;
            SEAShowtime *showtime = [[SEAShowtime alloc] initWithDictionary:showtimeDictionary];
            NSString *theatreId = [NSString stringWithFormat:@"%@", @(showtime.theatreId)];
            SEAMovie *movie = [self movieForId:showtime.movieId];
            if (!movie.showtimes[theatreId] || ![movie.showtimes[theatreId] isKindOfClass:[NSMutableArray class]]) {
              movie.showtimes[theatreId] = [NSMutableArray new];
            }
            [movie.showtimes[theatreId] addObject:showtime];
            if (!self.showtimes[theatreId]) {
              self.showtimes[theatreId] = [NSMutableArray new];
            }
            [self.showtimes[theatreId] addObject:showtime];
          } else {
            [subscriber sendError:nil];
          }
        }
        NSMutableArray *toRemove = [NSMutableArray new];
        for (SEAMovie *movie in self.nowPlayingMovies) {
          if (movie.showtimes.count == 0) {
            [toRemove addObject:movie];
          } else {
            [movie processShowtimes];
          }
        }
        [self.nowPlayingMovies removeObjectsInArray:toRemove];
        [self saveNowPlayingMovies];
        [self saveShowtimes];
        DDLogInfo(@"✓ %@ now playing movies loaded", @(self.nowPlayingMovies.count));
        NSArray *sortedMovies = [SEADataManager moviesSortedByShowtimes:self.nowPlayingMovies];
        self.featuredMovies = [sortedMovies subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)5, sortedMovies.count))];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNowPlayingMoviesLoadedNotification object:nil];
        [subscriber sendNext:self.nowPlayingMovies];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:nil];
      }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
};

- (RACSignal *)loadTheatres {
  if (self.fromCache) {
    [self restoreTheatres];
  }
  if (self.theatres && self.theatres.count > 0) {
    DDLogInfo(@"✓ %@ theatres loaded from cache", @(self.theatres.count));
    [[NSNotificationCenter defaultCenter] postNotificationName:kTheatresLoadedNotification object:nil];
    return [RACSignal return :self.theatres];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    self.theatres = [NSMutableArray new];
    [self.manager GET:kAllTheatresQuery parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
      if ([responseObject isKindOfClass:[NSArray class]]) {
        NSArray *theatresDictionaries = (NSArray *)responseObject;
        self.starredTheatresIds = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kStarredTheatresIdsKey];
        for (id theatreObject in theatresDictionaries) {
          if ([theatreObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *theatreDictionary = (NSDictionary *)theatreObject;
            SEATheatre *theatre = [[SEATheatre alloc] initWithDictionary:theatreDictionary];
            for (NSNumber *starredTheatreId in self.starredTheatresIds) {
              if ([starredTheatreId integerValue] == theatre.id) {
                theatre.favorite = YES;
              }
            }
            [self.theatres addObject:theatre];
          } else {
            [subscriber sendError:nil];
          }
        }
        [self saveTheatres];
        DDLogInfo(@"✓ %@ theatres loaded", @(self.theatres.count));
        [[NSNotificationCenter defaultCenter] postNotificationName:kTheatresLoadedNotification object:nil];
        [subscriber sendNext:self.theatres];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:nil];
      }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)loadNews {
  if (self.fromCache) {
    [self restoreNews];
  }
  if (self.news && self.news.count > 0) {
    DDLogInfo(@"✓ %@ news entries loaded from cache", @(self.news.count));
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewsLoadedNotification object:nil];
    return [RACSignal return :self.news];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    self.news = [NSMutableArray new];
    [self.manager GET:kAllNewsQuery parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
      if ([responseObject isKindOfClass:[NSArray class]]) {
        NSArray *newsDictionaries = (NSArray *)responseObject;
        for (id newsObject in newsDictionaries) {
          if ([newsObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *newsDictionary = (NSDictionary *)newsObject;
            SEANewsEntry *newsEntry = [self newsEntryFromDictionary:newsDictionary];
            [self.news addObject:newsEntry];
          } else {
            [subscriber sendError:nil];
          }
        }
        [self saveNews];
        DDLogInfo(@"✓ %@ news entries loaded", @(self.news.count));
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewsLoadedNotification object:nil];
        [subscriber sendNext:self.news];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:nil];
      }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (SEANewsEntry *)newsEntryFromDictionary:(NSDictionary *)dictionary {
  SEANewsEntry *newsEntry = [[SEANewsEntry alloc] initWithDictionary:dictionary];
  if (self.cachedNews.count > 0) {
    for (SEANewsEntry *cachedNewsEntry in self.cachedNews) {
      if (newsEntry.id == cachedNewsEntry.id) {
        return cachedNewsEntry;
      }
    }
  }
  return newsEntry;
}

- (void)reset {
  self.nowPlayingMovies = nil;
  self.comingSoonMovies = nil;
  self.theatres = nil;
  self.showtimes = nil;
  self.news = nil;
  self.loaded = NO;
}

#pragma mark Spotlight

- (RACSignal *)setUpSpotlightSearch {
  if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
    return [RACSignal empty];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:^(NSError *deleteError) {
      if (deleteError) {
        [subscriber sendError:deleteError];
      } else {
        NSMutableArray *signals = [NSMutableArray new];
        for (SEAMovie *movie in self.nowPlayingMovies) {
          [signals addObject:[self getSearchableItemForMovie:movie]];
        }
        [[[RACSignal merge:signals] collect] subscribeNext:^(NSArray *items) {
          [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:items completionHandler:^(NSError *indexError) {
            if (indexError) {
              [subscriber sendError:indexError];
            } else {
              DDLogInfo(@"✓ %@ movies saved to spotlight index", @(items.count));
              [subscriber sendCompleted];
            }
          }];
        }];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)getSearchableItemForMovie:(SEAMovie *)movie {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[movie.poster getImage] subscribeNext:^(RACTuple *tuple) {
      UIImage *image = [tuple first];
      CSSearchableItemAttributeSet *attibuteSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(__bridge NSString *)kUTTypeImage];
      attibuteSet.title = movie.title;
      NSMutableString *description = [movie.subtitle mutableCopy];
      if ([self citySupported] && [self localShowtimesForMovie:movie].count > 0) {
        NSInteger showtimesCount = (NSInteger)[self localShowtimesForMovie:movie].count;
        [description appendFormat:@"\n%@ %@ в %@", @(showtimesCount), [NSString getNumEnding:showtimesCount endings:@[@"сеанс", @"сеанса", @"cеансов"]], [SEALocationManager sharedInstance].currentCity];
      }
      attibuteSet.contentDescription = description;
      NSMutableArray *keywords = [@[@"сеансы", @"кино", @"афиша", movie.title, movie.originalTitle] mutableCopy];
      [keywords addObjectsFromArray:movie.genre];
      attibuteSet.keywords = keywords;
      if (image) {
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
        attibuteSet.thumbnailData = imageData;
      }

      CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:[NSString stringWithFormat:@"movie-%@", @(movie.id)] domainIdentifier:@"seansy-movies" attributeSet:attibuteSet];
      [subscriber sendNext:item];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

#pragma mark Archiving

- (void)restoreNowPlayingMovies {
  NSData *encodedMovies = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kNowPlayingMoviesKey];
  if (encodedMovies) {
    NSArray *decodedMovies = [NSKeyedUnarchiver unarchiveObjectWithData:encodedMovies];
    if (decodedMovies) {
      self.nowPlayingMovies = [decodedMovies mutableCopy];
    }
  }
}

- (void)restoreComingSoonMovies {
  NSData *encodedMovies = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kComingSoonMoviesKey];
  if (encodedMovies) {
    NSArray *decodedMovies = [NSKeyedUnarchiver unarchiveObjectWithData:encodedMovies];
    if (decodedMovies) {
      self.comingSoonMovies = [decodedMovies mutableCopy];
    }
  }
}

- (void)restoreTheatres {
  NSData *encodedTheatres = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kTheatresKey];
  if (encodedTheatres) {
    NSArray *decodedTheatres = [NSKeyedUnarchiver unarchiveObjectWithData:encodedTheatres];
    if (decodedTheatres) {
      self.theatres = [decodedTheatres mutableCopy];
    }
  }
}

- (void)restoreShowtimes {
  NSData *encodedShowtimes = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kShowtimesKey];
  if (encodedShowtimes) {
    NSDictionary *decodedShowtimes = [NSKeyedUnarchiver unarchiveObjectWithData:encodedShowtimes];
    if (decodedShowtimes) {
      self.showtimes = [decodedShowtimes mutableCopy];
    }
  }
}

- (void)restoreNews {
  NSData *encodedNews = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kNewsKey];
  if (encodedNews) {
    NSArray *decodedNews = [NSKeyedUnarchiver unarchiveObjectWithData:encodedNews];
    if (decodedNews) {
      self.news = [decodedNews mutableCopy];
    }
  }
}

- (void)saveNowPlayingMovies {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.nowPlayingMovies] forKey:kNowPlayingMoviesKey];
}

- (void)saveComingSoonMovies {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.comingSoonMovies] forKey:kComingSoonMoviesKey];
}

- (void)saveTheatres {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.theatres] forKey:kTheatresKey];
}

- (void)saveShowtimes {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.showtimes] forKey:kShowtimesKey];
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSDate dateForHour:kUTCTimeForNextUpdate] forKey:kOfflineDataExpirationDateKey];
}

- (void)saveNews {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.news] forKey:kNewsKey];
}

- (void)clearCache {
  for (NSString *key in @[kNowPlayingMoviesKey, kComingSoonMoviesKey, kTheatresKey, kShowtimesKey, kNewsKey]) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] removeObjectForKey:key];
  }
}

- (void)saveStarredTheatresIds {
  NSMutableArray *starredTheatres = [NSMutableArray new];
  for (SEATheatre *theatre in self.theatres) {
    if (theatre.isFavorite) {
      [starredTheatres addObject:@(theatre.id)];
    }
  }
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:starredTheatres forKey:kStarredTheatresIdsKey];
}

#pragma mark Helpers

- (BOOL)citySupported {
  if ([SEALocationManager sharedInstance].currentCity) {
    return [[self allCities] containsObject:[SEALocationManager sharedInstance].currentCity];
  }
  return NO;
}

+ (BOOL)hasPassed:(NSDate *)date {
  NSTimeInterval serverDateOffset = [NSTimeZone timeZoneWithName:@"Asia/Almaty"].secondsFromGMT;
  NSTimeInterval localDateOffset = [NSTimeZone defaultTimeZone].secondsFromGMT;

  NSDate *showtimeDate = [date dateByAddingTimeInterval:serverDateOffset - localDateOffset];
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *dateComponents = [gregorian components:NSCalendarUnitHour fromDate:showtimeDate];
  NSInteger hours = [dateComponents hour];
  if (hours < kNewDayStartHour) {
    showtimeDate = [showtimeDate dateByAddingTimeInterval:60 * 60 * 24];
  }
  NSDate *localDate = [[NSDate date] dateByAddingTimeInterval:serverDateOffset - localDateOffset];

  return [showtimeDate compare:localDate] == NSOrderedAscending;
}

- (NSTimeInterval)timeIntervalFromString:(NSString *)string {
  NSDate *end = [self.timeFormatter dateFromString:string];
  NSTimeInterval interval = [end timeIntervalSinceDate:self.timeStartDate];
  return interval;
}

+ (NSInteger)averageAdultTicketPrice:(NSArray *)showtimes {
  NSInteger count = 0;
  NSInteger totalPrice = 0;
  for (SEAShowtime *showtime in showtimes) {
    NSString *adultPrice = showtime.prices[@"adult"];
    if (adultPrice.length > 0) {
      count++;
      totalPrice += [adultPrice integerValue];
    }
  }
  if (count > 0) {
    return totalPrice / count;
  } else {
    return NSNotFound;
  }
}

#pragma mark Retrieving

- (SEAMovie *)movieForId:(NSInteger)id {
  for (SEAMovie *movie in self.nowPlayingMovies) {
    if (movie.id == id) {
      return movie;
    }
  }
  return nil;
}

- (SEATheatre *)theatreForId:(NSInteger)id {
  for (SEATheatre *theatre in self.theatres) {
    if (theatre.id == id) {
      return theatre;
    }
  }
  return nil;
}

- (NSArray *)moviesForCity:(NSString *)city {
  NSMutableArray *movies = [NSMutableArray new];
  NSArray *theatres = [self theatresForCity:city];
  for (SEATheatre *theatre in theatres) {
    [movies addObjectsFromArray:[self moviesForTheatre:theatre]];
  }
  return [[NSSet setWithArray:movies] allObjects];
}

- (NSArray *)moviesForTheatre:(SEATheatre *)theatre {
  NSMutableArray *movies = [NSMutableArray new];
  for (SEAMovie *movie in self.nowPlayingMovies) {
    if ([movie showtimesForTheatreId:[@(theatre.id)stringValue]]) {
      [movies addObject:movie];
    }
  }
  return movies;
}

- (NSArray *)theatresForMovie:(SEAMovie *)movie {
  NSMutableArray *theatres = [NSMutableArray new];
  for (id theatreId in movie.showtimes) {
    if ([movie showtimesForTheatreId:theatreId].count > 0) {
      [theatres addObject:[self theatreForId:[theatreId integerValue]]];
    }
  }
  return theatres;
}

- (NSArray *)theatresForMovies:(NSArray *)movies {
  NSMutableArray *theatres = [NSMutableArray new];
  for (SEAMovie *movie in movies) {
    [theatres addObjectsFromArray:[self theatresForMovie:movie]];
  }
  return [[NSSet setWithArray:theatres] allObjects];
}

- (NSArray *)theatresForShowtimes:(NSArray *)showtimes {
  NSMutableArray *theatres = [NSMutableArray new];
  for (SEAShowtime *showtime in showtimes) {
    [theatres addObject:[self theatreForId:showtime.theatreId]];
  }
  return [[NSSet setWithArray:theatres] allObjects];
}

- (NSArray *)theatresForCity:(NSString *)city {
  NSArray *theatres = [self.theatres filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary *bindings) {
    return [[evaluatedObject city] isEqualToString:city];
  }]];

  return theatres;
}

- (NSArray *)theatresForMovie:(SEAMovie *)movie city:(NSString *)city {
  NSArray *movieTheatres = [self theatresForMovie:movie];
  NSArray *localTheatres = [self theatresForCity:city];
  NSMutableSet *intersection = [NSMutableSet setWithArray:movieTheatres];
  [intersection intersectSet:[NSSet setWithArray:localTheatres]];
  NSArray *theatres = [intersection allObjects];
  if (theatres.count == 0) {
    theatres = localTheatres;
  }
  return [self sortedTheatres:theatres];
}

- (NSArray *)moviesForShowtimes:(NSArray *)showtimes {
  NSMutableArray *movies = [NSMutableArray new];
  for (SEAShowtime *showtime in showtimes) {
    [movies addObject:[self movieForId:showtime.movieId]];
  }
  return [[NSSet setWithArray:movies] allObjects];
}

- (NSArray *)showtimesForMovies:(NSArray *)movies {
  NSMutableArray *showtimes = [NSMutableArray new];
  for (SEAMovie *movie in movies) {
    for (id theatreId in movie.showtimes) {
      [showtimes addObjectsFromArray:[movie showtimesForTheatreId:theatreId]];
    }
  }
  return [SEADataManager showtimesSortedByTime:showtimes];
}

- (NSArray *)datesForShowtimes:(NSArray *)showtimes {
  NSMutableArray *dates = [NSMutableArray new];
  for (SEAShowtime *showtime in showtimes) {
    [dates addObject:showtime.date];
  }
  NSTimeInterval serverDateOffset = [NSTimeZone timeZoneWithName:@"Asia/Almaty"].secondsFromGMT;
  NSTimeInterval localDateOffset = [NSTimeZone defaultTimeZone].secondsFromGMT;
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

  return [[[NSSet setWithArray:dates] allObjects] sortedArrayUsingComparator:^(id i1, id i2) {
    NSDate *date1 = [i1 dateByAddingTimeInterval:serverDateOffset - localDateOffset];
    NSDateComponents *date1Components = [gregorian components:NSCalendarUnitHour fromDate:date1];
    if ([date1Components hour] < kNewDayStartHour) {
      date1 = [date1 dateByAddingTimeInterval:60 * 60 * 24];
    }
    NSDate *date2 = [i2 dateByAddingTimeInterval:serverDateOffset - localDateOffset];
    NSDateComponents *date2Components = [gregorian components:NSCalendarUnitHour fromDate:date2];
    if ([date2Components hour] < kNewDayStartHour) {
      date2 = [date2 dateByAddingTimeInterval:60 * 60 * 24];
    }
    return [date1 compare:date2];
  }];
}

- (NSArray *)allGenresForNowPlayingMovies {
  NSMutableArray *allGenres = [NSMutableArray new];
  for (SEAMovie *movie in self.nowPlayingMovies) {
    [allGenres addObjectsFromArray:movie.genre];
  }
  // Get number of occurences for each genre
  NSCountedSet *countedSet = [[NSCountedSet alloc] initWithArray:allGenres];
  // Remove duplicates
  allGenres = [NSMutableArray arrayWithArray:[[NSSet setWithArray:allGenres] allObjects]];
  return [allGenres sortedArrayUsingComparator:^(NSString *i1, NSString *i2) {
    NSUInteger count1 = [countedSet countForObject:i1];
    NSUInteger count2 = [countedSet countForObject:i2];
    if (count1 > count2) {
      return NSOrderedAscending;
    } else if (count1 < count2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

- (NSArray *)allDatesForComingSoonMovies {
  NSMutableArray *allDates = [NSMutableArray new];
  for (SEAMovie *movie in self.comingSoonMovies) {
    if ([allDates indexOfObject:movie.date] == NSNotFound) {
      [allDates addObject:movie.date];
    }
  }
  return [allDates sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)allShowtimes {
  return [self showtimesForMovies:self.nowPlayingMovies];
}

- (NSArray *)allCities {
  return [[self.theatres valueForKeyPath:@"@distinctUnionOfObjects.city"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

#pragma mark Filter Values

- (CGFloat)minimumRatingForNowPlayingMovies {
  NSArray *sortedMovies = [SEADataManager moviesSortedByRating:[self localNowPlayingMovies]];
  SEAMovie *movie = [sortedMovies lastObject];
  return movie.averageRating;
}

- (CGFloat)maximumRatingForNowPlayingMovies {
  NSArray *sortedMovies = [SEADataManager moviesSortedByRating:[self localNowPlayingMovies]];
  SEAMovie *movie = [sortedMovies firstObject];
  return movie.averageRating;
}

- (NSTimeInterval)minimumRuntimeForNowPlayingMovies {
  NSArray *sortedMovies = [SEADataManager moviesSortedByRuntime:[self localNowPlayingMovies]];
  SEAMovie *movie = [sortedMovies firstObject];
  return movie.runtime;
}

- (NSTimeInterval)maximumRuntimeForNowPlayingMovies {
  NSArray *sortedMovies = [SEADataManager moviesSortedByRuntime:[self localNowPlayingMovies]];
  SEAMovie *movie = [sortedMovies lastObject];
  return movie.runtime;
}

#pragma mark Local

- (NSArray *)localNowPlayingMovies {
  NSArray *movies;
  if ([self citySupported]) {
    movies = [self moviesForCity:[SEALocationManager sharedInstance].currentCity];
  }
  if (movies.count == 0 || !movies) {
    movies = self.nowPlayingMovies;
  }
  return [self sortedMovies:movies];
}

- (NSArray *)localTheatresForMovie:(SEAMovie *)movie {
  if ([self citySupported]) {
    return [self theatresForMovie:movie city:[SEALocationManager sharedInstance].currentCity];
  } else {
    return nil;
  }
}

- (NSArray *)localTheatresForMovies:(NSArray *)movies {
  if ([self citySupported]) {
    NSArray *moviesTheatres = [self theatresForMovies:movies];
    NSArray *localTheatres = [self theatresForCity:[SEALocationManager sharedInstance].currentCity];
    NSMutableSet *intersection = [NSMutableSet setWithArray:moviesTheatres];
    [intersection intersectSet:[NSSet setWithArray:localTheatres]];
    NSArray *theatres = [intersection allObjects];
    if (theatres.count == 0) {
      theatres = localTheatres;
    }
    return [self sortedTheatres:theatres];
  } else {
    return nil;
  }
}

- (NSArray *)localShowtimesForMovies:(NSArray *)movies {
  if ([SEALocationManager sharedInstance].currentCity) {
    NSArray *allShowtimes = [self showtimesForMovies:movies];
    NSArray *localTheatreIds = [[self localTheatresForMovies:movies] valueForKeyPath:@"id"];
    return [allShowtimes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAShowtime *showtime, NSDictionary *bindings) {
      return [localTheatreIds containsObject:@(showtime.theatreId)];
    }]];
  } else {
    return nil;
  }
}

- (NSArray *)localShowtimesForMovie:(SEAMovie *)movie {
  if ([SEALocationManager sharedInstance].currentCity) {
    NSMutableArray *allShowtimes = [NSMutableArray new];
    for (id theatreId in movie.showtimes) {
      [allShowtimes addObjectsFromArray:[movie showtimesForTheatreId:theatreId]];
    }
    NSArray *localTheatreIds = [[self localTheatresForMovie:movie] valueForKeyPath:@"id"];
    return [allShowtimes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAShowtime *showtime, NSDictionary *bindings) {
      return [localTheatreIds containsObject:@(showtime.theatreId)];
    }]];
  } else {
    return nil;
  }
}

#pragma mark Sorting

- (NSArray *)sortedMovies:(NSArray *)movies {
  SEAMoviesSortBy sortBy = (SEAMoviesSortBy)[[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kMoviesSortByKey];
  switch (sortBy) {
    case SEAMoviesSortByShowtimesCount:
      movies = [NSMutableArray arrayWithArray:[SEADataManager moviesSortedByShowtimes:movies]];
      break;
    case SEAMoviesSortByName:
      movies = [NSMutableArray arrayWithArray:[SEADataManager moviesSortedAlphabetically:movies]];
      break;
    case SEAMoviesSortByPopularity:
      movies = [NSMutableArray arrayWithArray:[SEADataManager moviesSortedByPopularity:movies]];
      break;
    case SEAMoviesSortByRating:
      movies = [NSMutableArray arrayWithArray:[SEADataManager moviesSortedByRating:movies]];
      break;
    default:
      break;
  }
  return movies;
}

+ (NSArray *)moviesSortedByShowtimes:(NSArray *)movies {
  return [movies sortedArrayUsingComparator:^(SEAMovie *i1, SEAMovie *i2) {
    NSInteger count1 = 0;
    for (id key in i1.showtimes) {
      NSArray *showtimes = [i1 showtimesForTheatreId:key];
      count1 += showtimes.count;
    }
    NSInteger count2 = 0;
    for (id key in i2.showtimes) {
      NSArray *showtimes = [i2 showtimesForTheatreId:key];
      count2 += showtimes.count;
    }
    if (count1 > count2) {
      return NSOrderedAscending;
    } else if (count1 < count2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)moviesSortedAlphabetically:(NSArray *)movies {
  return [movies sortedArrayUsingComparator:^(SEAMovie *i1, SEAMovie *i2) {
    NSString *title1 = i1.title;
    NSString *title2 = i2.title;
    return [title1 compare:title2];
  }];
}

+ (NSArray *)moviesSortedByPopularity:(NSArray *)movies {
  return [movies sortedArrayUsingComparator:^(SEAMovie *i1, SEAMovie *i2) {
    NSInteger pop1 = i1.popularity;
    NSInteger pop2 = i2.popularity;
    if (pop1 < pop2) {
      return NSOrderedAscending;
    } else if (pop1 > pop2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)moviesSortedByRating:(NSArray *)movies {
  return [movies sortedArrayUsingComparator:^(SEAMovie *i1, SEAMovie *i2) {
    CGFloat rating1 = i1.averageRating;
    CGFloat rating2 = i2.averageRating;
    if (rating1 > rating2) {
      return NSOrderedAscending;
    } else if (rating1 < rating2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)moviesSortedByRuntime:(NSArray *)movies {
  return [movies sortedArrayUsingComparator:^(SEAMovie *i1, SEAMovie *i2) {
    NSTimeInterval runtime1 = i1.runtime;
    NSTimeInterval runtime2 = i2.runtime;
    if (runtime1 < runtime2) {
      return NSOrderedAscending;
    } else if (runtime1 > runtime2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)moviesSortedByDate:(NSArray *)movies {
  return [movies sortedArrayUsingComparator:^(SEAMovie *i1, SEAMovie *i2) {
    NSDate *date1 = i1.date;
    NSDate *date2 = i2.date;
    return [date1 compare:date2];
  }];
}

- (NSArray *)sortedTheatres:(NSArray *)theatres {
  NSArray *sortedFavorites = [self sortedTheatres:theatres favorites:YES];
  NSArray *sortedNonFavorites = [self sortedTheatres:theatres favorites:NO];
  return [sortedFavorites arrayByAddingObjectsFromArray:sortedNonFavorites];
}

- (NSArray *)sortedTheatres:(NSArray *)theatres favorites:(BOOL)favorites {
  theatres = [theatres filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEATheatre *theatre, NSDictionary *bindings) {
    return favorites ? theatre.isFavorite : !theatre.isFavorite;
  }]];
  SEATheatresSortBy sortBy = (SEATheatresSortBy)[[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kTheatresSortByKey];
  switch (sortBy) {
    case SEATheatresSortByShowtimesCount:
      theatres = [NSMutableArray arrayWithArray:[SEADataManager theatresSortedByShowtimesCount:theatres]];
      break;
    case SEAMoviesSortByName:
      theatres = [NSMutableArray arrayWithArray:[SEADataManager theatresSortedAlphabetically:theatres]];
      break;
    case SEATheatresSortByPrice:
      theatres = [NSMutableArray arrayWithArray:[SEADataManager theatresSortedByPrice:theatres]];
      break;
    case SEATheatresSortByDistance: {
      if ([SEALocationManager sharedInstance].actualCity && [[SEALocationManager sharedInstance].currentCity isEqualToString:[SEALocationManager sharedInstance].actualCity]) {
        theatres = [NSMutableArray arrayWithArray:[SEADataManager theatresSortedByDistance:theatres]];
      } else {
        theatres = [NSMutableArray arrayWithArray:[SEADataManager theatresSortedByShowtimesCount:theatres]];
      }
    }
    break;
    default:
      break;
  }
  return theatres;
}

+ (NSArray *)theatresSortedAlphabetically:(NSArray *)theatres {
  return [theatres sortedArrayUsingComparator:^(SEATheatre *i1, SEATheatre *i2) {
    NSString *name1 = i1.name;
    NSString *name2 = i2.name;
    return [name1 compare:name2];
  }];
}

+ (NSArray *)theatresSortedByDistance:(NSArray *)theatres {
  return [theatres sortedArrayUsingComparator:^(SEATheatre *i1, SEATheatre *i2) {
    CLLocationDistance distance1 = [[SEALocationManager sharedInstance] distanceFromLocation:i1.location];
    CLLocationDistance distance2 = [[SEALocationManager sharedInstance] distanceFromLocation:i2.location];
    if (distance1 < distance2) {
      return NSOrderedAscending;
    } else if (distance1 > distance2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)theatresSortedByShowtimes:(NSArray *)theatres movie:(SEAMovie *)movie {
  return [theatres sortedArrayUsingComparator:^(SEATheatre *i1, SEATheatre *i2) {
    NSArray *showtimes1 = [movie showtimesForTheatreId:[NSString stringWithFormat:@"%@", @(i1.id)]];
    NSArray *showtimes2 = [movie showtimesForTheatreId:[NSString stringWithFormat:@"%@", @(i2.id)]];
    NSTimeInterval time1 = 48 * 3600;
    NSTimeInterval time2 = 48 * 3600;
    if (showtimes1.count > 0) {
      for (SEAShowtime *showtime in showtimes1) {
        if (![showtime hasPassed]) {
          time1 = showtime.time;
          break;
        }
      }
    }
    if (showtimes2.count > 0) {
      for (SEAShowtime *showtime in showtimes2) {
        if (![showtime hasPassed]) {
          time2 = showtime.time;
          break;
        }
      }
    }
    if (time1 / 3600 < kNewDayStartHour) { time1 += 24 * 3600; }
    if (time2 / 3600 < kNewDayStartHour) { time2 += 24 * 3600; }
    if (time1 < time2) {
      return NSOrderedAscending;
    } else if (time1 > time2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)theatresSortedByShowtimesCount:(NSArray *)theatres {
  return [theatres sortedArrayUsingComparator:^(SEATheatre *i1, SEATheatre *i2) {
    NSUInteger count1 = [[SEADataManager sharedInstance].showtimes[[NSString stringWithFormat:@"%@", @(i1.id)]] count];
    NSUInteger count2 = [[SEADataManager sharedInstance].showtimes[[NSString stringWithFormat:@"%@", @(i2.id)]] count];
    if (count1 > count2) {
      return NSOrderedAscending;
    } else if (count1 < count2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)theatresSortedByPrice:(NSArray *)theatres {
  return [theatres sortedArrayUsingComparator:^(SEATheatre *i1, SEATheatre *i2) {
    NSInteger count1 = [self averageAdultTicketPrice:[SEADataManager sharedInstance].showtimes[[NSString stringWithFormat:@"%@", @(i1.id)]]];
    NSInteger count2 = [self averageAdultTicketPrice:[SEADataManager sharedInstance].showtimes[[NSString stringWithFormat:@"%@", @(i2.id)]]];
    if (count1 < count2) {
      return NSOrderedAscending;
    } else if (count1 > count2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)showtimesSortedByTime:(NSArray *)showtimes {
  return [showtimes sortedArrayUsingComparator:^(SEAShowtime *i1, SEAShowtime *i2) {
    NSTimeInterval time1 = i1.time;
    if (time1 / 3600 < kNewDayStartHour) {
      time1 += 24 * 3600;
    }
    NSTimeInterval time2 = i2.time;
    if (time2 / 3600 < kNewDayStartHour) {
      time2 += 24 * 3600;
    }
    if (time1 < time2) {
      return NSOrderedAscending;
    } else if (time1 > time2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

+ (NSArray *)newsSortedByDate:(NSArray *)news {
  return [news sortedArrayUsingComparator:^(SEANewsEntry *i1, SEANewsEntry *i2) {
    NSDate *date1 = i1.date;
    NSDate *date2 = i2.date;
    return [date2 compare:date1];
  }];
}

#pragma mark Filtering

- (NSArray *)filteredMovies:(NSArray *)movies {
  NSArray *filteredMovies = movies;
  if ([SEAMoviesFilter sharedInstance].ratingFilter >= 0) {
    filteredMovies = [SEADataManager filterMovies:filteredMovies rating:[SEAMoviesFilter sharedInstance].ratingFilter];
  }
  if ([SEAMoviesFilter sharedInstance].runtimeFilter >= 0) {
    filteredMovies = [SEADataManager filterMovies:filteredMovies runtime:[SEAMoviesFilter sharedInstance].runtimeFilter];
  }
  if ([SEAMoviesFilter sharedInstance].childrenFilter) {
    filteredMovies = [SEADataManager filterMoviesForChildren:filteredMovies];
  }
  if ([SEAMoviesFilter sharedInstance].genresFilter.count > 0) {
    filteredMovies = [SEADataManager filterMovies:filteredMovies genres:[SEAMoviesFilter sharedInstance].genresFilter];
  }
  return filteredMovies;
}

+ (NSArray *)filterMovies:(NSArray *)movies rating:(NSInteger)rating {
  return [movies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAMovie *movie, NSDictionary *bindings) {
    return movie.averageRating >= rating;
  }]];
}

+ (NSArray *)filterMovies:(NSArray *)movies runtime:(NSTimeInterval)runtime {
  return [movies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAMovie *movie, NSDictionary *bindings) {
    return movie.runtime <= runtime;
  }]];
}

+ (NSArray *)filterMovies:(NSArray *)movies genres:(NSArray *)genres {
  return [movies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAMovie *movie, NSDictionary *bindings) {
    NSMutableSet *intersection = [NSMutableSet setWithArray:movie.genre];
    [intersection intersectSet:[NSSet setWithArray:genres]];
    NSArray *commonGenres = [intersection allObjects];
    return [commonGenres isEqualToArray:genres];
  }]];
}

+ (NSArray *)filterMoviesForChildren:(NSArray *)movies {
  return [movies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAMovie *movie, NSDictionary *bindings) {
    return movie.age < 16 && movie.age >= 0;
  }]];
}

+ (NSArray *)filterMovies:(NSArray *)movies date:(NSDate *)date {
  return [movies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAMovie *movie, NSDictionary *bindings) {
    return [movie.date isEqualToDate:date];
  }]];
}

+ (NSArray *)filterShowtimes:(NSArray *)showtimes date:(NSDate *)date {
  return [showtimes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAShowtime *showtime, NSDictionary *bindings) {
    return showtime.date == date;
  }]];
}

+ (NSArray *)filterShowtimes:(NSArray *)showtimes theatreId:(NSInteger)theatreId {
  return [showtimes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAShowtime *showtime, NSDictionary *bindings) {
    return showtime.theatreId == theatreId;
  }]];
}

+ (NSArray *)filterShowtimes:(NSArray *)showtimes movieId:(NSInteger)movieId {
  return [showtimes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (SEAShowtime *showtime, NSDictionary *bindings) {
    return showtime.movieId == movieId;
  }]];
}

+ (NSArray *)filterPassedShowtimes:(NSArray *)showtimes {
  return [showtimes filteredArrayUsingPredicate:
          [NSPredicate predicateWithBlock:^BOOL (SEAShowtime *showtime, NSDictionary *bindings) {
    return ![self hasPassed:showtime.date];
  }]];
}

@end
