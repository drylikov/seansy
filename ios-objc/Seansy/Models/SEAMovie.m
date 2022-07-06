#import "SEAMovie.h"

#import "NSString+SEAHelpers.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAShowtime.h"
#import "SEAStill.h"
#import "UIFont+SEASizes.h"

static NSString *const kMovieTitleKey = @"title";
static NSString *const kMovieOriginalTitleKey = @"originalTitle";
static NSString *const kMovieYearKey = @"year";
static NSString *const kMovieKpRatingKey = @"kpRating";
static NSString *const kMovieRtCriticsKey = @"rtCriticsRating";
static NSString *const kMovieRtAudienceKey = @"rtAudienceRating";
static NSString *const kMovieImdbRatingKey = @"imdbRating";
static NSString *const kMovieGenreKey = @"genre";
static NSString *const kMovieRuntimeKey = @"runtime";
static NSString *const kMovieAgeKey = @"age";
static NSString *const kMovieSynopsisKey = @"synopsis";
static NSString *const kMoviePosterUrlKey = @"posterUrl";
static NSString *const kMoviePosterKey = @"poster";
static NSString *const kMovieTrailerIdKey = @"trailerId";
static NSString *const kMovieDirectorKey = @"director";
static NSString *const kMovieScriptKey = @"script";
static NSString *const kMovieCastKey = @"cast";
static NSString *const kMoviePopularityKey = @"popularity";
static NSString *const kMovieDateKey = @"date";
static NSString *const kMovieFeaturedKey = @"featured";
static NSString *const kMovieStillsKey = @"stills";
static NSString *const kMovieReviewsKey = @"reviews";
static NSString *const kMovieBonusSceneKey = @"bonusScene";

@interface SEAMovie ()

@property (nonatomic) NSMutableDictionary *groupedShowtimes;
@property (nonatomic) NSNumber *averageRatingNumber;

@end

@implementation SEAMovie

#pragma mark Initialization

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (!self) {
    return nil;
  }

  _id = [[self stringFromDictionary:dictionary key:kIdKey] integerValue];
  _title = [self stringFromDictionary:dictionary key:kMovieTitleKey] ? : @"";
  _originalTitle = [self stringFromDictionary:dictionary key:kMovieOriginalTitleKey] ? : @"";
  _year = [[self stringFromDictionary:dictionary key:kMovieYearKey] integerValue];
  NSString *movieKpRating = [self stringFromDictionary:dictionary key:kMovieKpRatingKey] ? : @"";
  NSString *movieImdbRating = [self stringFromDictionary:dictionary key:kMovieImdbRatingKey] ? : @"";
  NSString *movieRtCriticsRating = [self stringFromDictionary:dictionary key:kMovieRtCriticsKey] ? : @"";
  NSString *movieRtAudienceRating = [self stringFromDictionary:dictionary key:kMovieRtAudienceKey] ? : @"";
  _ratings = @[movieKpRating, movieImdbRating, movieRtCriticsRating, movieRtAudienceRating];
  _genre = [self arrayFromDictionary:dictionary key:kMovieGenreKey];
  _runtime = [[self stringFromDictionary:dictionary key:kMovieRuntimeKey] doubleValue] * 60;
  _age = [[self stringFromDictionary:dictionary key:kMovieAgeKey] integerValue];
  _synopsis = [self stringFromDictionary:dictionary key:kMovieSynopsisKey];
  NSURL *posterUrl = [NSURL URLWithString:[self stringFromDictionary:dictionary key:kMoviePosterUrlKey]];
  _poster = [[SEAPoster alloc] initWithUrl:posterUrl];
  NSURL *movieBackdropUrl = [NSURL URLWithString:[self stringFromDictionary:dictionary key:kBackdropUrlKey]];
  _trailerId = [self stringFromDictionary:dictionary key:kMovieTrailerIdKey];

  if (!movieBackdropUrl && _trailerId) {
    movieBackdropUrl = [NSURL URLWithString:[NSString stringWithFormat:kYoutubeThumbnailUrlFormat, _trailerId]];
  }
  _director = [self arrayFromDictionary:dictionary key:kMovieDirectorKey];
  _script = [self arrayFromDictionary:dictionary key:kMovieScriptKey];
  NSString *castString = [self stringFromDictionary:dictionary key:kMovieCastKey] ? : @"";
  NSError *castError = nil;
  _cast = [NSJSONSerialization JSONObjectWithData:[castString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&castError];
  if (_cast.count == 0) {
    _cast = nil;
  }
  if (castError) {
    _cast = [self arrayFromDictionary:dictionary key:kMovieCastKey];
  }
  _popularity = [[self stringFromDictionary:dictionary key:kMoviePopularityKey] integerValue];
  if (_popularity == -1) {
    _popularity = 100000;
  }
  NSDateFormatter *dateFormatter = [NSDateFormatter new];
  [dateFormatter setDateFormat:@"dd.MM.yyyy"];
  _date = [dateFormatter dateFromString:[self stringFromDictionary:dictionary key:kMovieDateKey]];
  _featured = [[self stringFromDictionary:dictionary key:kMovieFeaturedKey] boolValue];
  id stillUrls = dictionary[kMovieStillsKey];
  if (stillUrls && stillUrls != [NSNull null]) {
    NSMutableArray *stills = [NSMutableArray new];
    for (NSString *stillUrl in stillUrls) {
      [stills addObject:[[SEAStill alloc] initWithUrl:[NSURL URLWithString:stillUrl]]];
    }
    _stills = stills.count > 0 ? stills : nil;
  }
  id reviews = dictionary[kMovieReviewsKey];
  if (reviews && reviews != [NSNull null]) {
    _reviews = [(NSArray *)reviews count] > 0 ? reviews : nil;
  }
  id bonusScene = dictionary[kMovieBonusSceneKey];
  if (bonusScene && bonusScene != [NSNull null]) {
    _bonusScene = [(NSDictionary *)bonusScene count] > 0 ? bonusScene : nil;
  }
  _backdrop = [[SEABackdrop alloc] initWithUrl:movieBackdropUrl];
  _showtimes = [NSMutableDictionary new];

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _id = [[decoder decodeObjectForKey:kIdKey] integerValue];
  _title = [decoder decodeObjectForKey:kMovieTitleKey];
  _originalTitle = [decoder decodeObjectForKey:kMovieOriginalTitleKey];
  _year = [[decoder decodeObjectForKey:kMovieYearKey] integerValue];
  NSString *kpRating = [decoder decodeObjectForKey:kMovieKpRatingKey];
  NSString *imdbRating = [decoder decodeObjectForKey:kMovieImdbRatingKey];
  NSString *rtCriticsRating = [decoder decodeObjectForKey:kMovieRtCriticsKey];
  NSString *rtAudienceRating = [decoder decodeObjectForKey:kMovieRtAudienceKey];
  _ratings = @[kpRating, imdbRating, rtCriticsRating, rtAudienceRating];
  _genre = [decoder decodeObjectForKey:kMovieGenreKey];
  _runtime = [[decoder decodeObjectForKey:kMovieRuntimeKey] integerValue];
  _age = [[decoder decodeObjectForKey:kMovieAgeKey] integerValue];
  _synopsis = [decoder decodeObjectForKey:kMovieSynopsisKey];
  _poster = [decoder decodeObjectForKey:kMoviePosterKey];
  _trailerId = [decoder decodeObjectForKey:kMovieTrailerIdKey];
  _director = [decoder decodeObjectForKey:kMovieDirectorKey];
  _script = [decoder decodeObjectForKey:kMovieScriptKey];
  _cast = [decoder decodeObjectForKey:kMovieCastKey];
  _popularity = [[decoder decodeObjectForKey:kMoviePopularityKey] integerValue];
  _date = [decoder decodeObjectForKey:kMovieDateKey];
  _featured = [[decoder decodeObjectForKey:kMovieFeaturedKey] boolValue];
  _stills = [decoder decodeObjectForKey:kMovieStillsKey];
  _reviews = [decoder decodeObjectForKey:kMovieReviewsKey];
  _backdrop = [decoder decodeObjectForKey:kBackdropKey];
  _showtimes = [decoder decodeObjectForKey:kShowtimesKey];

  return self;
}

#pragma mark NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: Title=%@, Original title=%@, Year=%@, Ratings=%@, Genres=%@, Runtime=%@, Age=%@, Synopsis=%@, Poster=%@, Backdrop url=%@, Trailer id=%@, Directors=%@, Script=%@, Cast=%@, Popularity=%@, Date=%@\n>", self.class, self.title, self.originalTitle, @(self.year), self.ratings, self.genre, @(self.runtime), @(self.age), self.synopsis, self.poster, self.backdrop.url, self.trailerId, self.director, self.script, self.cast, @(self.popularity), self.date];
}

#pragma mark Public

- (NSString *)shortDateString {
  NSLocale *ruLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
  NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMd" options:0 locale:ruLocale];
  NSDateFormatter *formatter = [NSDateFormatter new];
  formatter.locale = ruLocale;
  formatter.dateFormat = dateFormat;
  return [formatter stringFromDate:self.date];
}

- (NSString *)longDateString {
  NSString *date = [self shortDateString];
  NSInteger days = [self daysToDate];
  NSInteger weeks = (int)(days / 7.0 + 0.5);

  if (weeks == 1) {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ - Через неделю", @"{date} - Через неделю"), date];
  } else if (weeks > 1) {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ - Через %d %@", @"{date} - Через {number of weeks to date} {weeks with correct ending}"), date, weeks, [NSString getNumEnding:weeks endings:@[@"неделю", @"недели", @"недель"]]];
  } else if (days == 1) {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ - Завтра", @"{date} - Завтра"), date];
  } else {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ - Через %d %@", @"{date} - Через {number of days to date} {days with correct ending}"), date, days, [NSString getNumEnding:days endings:@[@"день", @"дня", @"дней"]]];
  }
}

- (NSString *)genreString {
  return [self.genre componentsJoinedByString:@", "];
}

- (NSString *)runtimeString {
  NSInteger runtime = (NSInteger)self.runtime;
  NSInteger minutes = (runtime / 60) % 60;
  NSInteger hours = (runtime / 3600);

  if (hours > 0 && minutes > 0) {
    return [NSString stringWithFormat:@"%@ %@ %@ %@", @(hours), [NSString getNumEnding:(hours) endings:@[@"час", @"часа", @"часов"]], @(minutes), [NSString getNumEnding:minutes endings:@[@"минута", @"минуты", @"минут"]]];
  } else if (minutes == 0) {
    return [NSString stringWithFormat:@"%@ %@", @(hours), [NSString getNumEnding:hours endings:@[@"час", @"часа", @"часов"]]];
  } else {
    return [NSString stringWithFormat:@"%@ %@", @(minutes), [NSString getNumEnding:minutes endings:@[@"минута", @"минуты", @"минут"]]];
  }
}

- (NSAttributedString *)kpRatingString {
  return [self ratingString:SEARatingSourceKinopoisk];
}

- (NSAttributedString *)imdbRatingString {
  return [self ratingString:SEARatingSourceIMDB];
}

- (NSAttributedString *)ratingString:(NSUInteger)index {
  NSString *ratingString = [NSString stringWithFormat:@"%.1f/10", (float)[self.ratings[index] floatValue]];
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:ratingString attributes:@{
                                                   NSForegroundColorAttributeName : [UIColor whiteColor],
                                                   NSFontAttributeName : [UIFont systemFontOfSize:[UIFont ratingFontSize]]
                                                 }];
  [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont smallTextFontSize]] range:[ratingString rangeOfString:@"/10"]];
  return attributedString;
}

- (NSAttributedString *)directorString {
  NSString *directorTitle = self.director.count > 1 ? @"Режиссеры:" : @"Режиссер:";
  NSString *joinedString = [NSString stringWithFormat:@"%@\r%@", directorTitle, [self.director componentsJoinedByString:@", "]];
  return [self highlightString:joinedString inRange:[joinedString rangeOfString:directorTitle]];
}

- (NSAttributedString *)scriptString {
  NSString *joinedString = [NSString stringWithFormat:@"Сценарий:\r%@", [self.script componentsJoinedByString:@", "]];
  return [self highlightString:joinedString inRange:[joinedString rangeOfString:@"Сценарий:"]];
}

- (NSAttributedString *)castString {
  NSString *joinedString = [NSString stringWithFormat:@"В главных ролях:\r%@", [self.cast componentsJoinedByString:@", "]];
  return [self highlightString:joinedString inRange:[joinedString rangeOfString:@"В главных ролях:"]];
}

- (NSString *)bonusSceneString {
  if (!self.bonusScene) {
    return nil;
  }
  if ([self.bonusScene[@"afterCredits"] boolValue] && [self.bonusScene[@"duringCredits"] boolValue]) {
    return NSLocalizedString(@"Бонусные сцены до и после титров", nil);
  } else if ([self.bonusScene[@"afterCredits"] boolValue]) {
    return NSLocalizedString(@"Бонусная сцена после титров", nil);
  } else if ([self.bonusScene[@"duringCredits"] boolValue]) {
    return NSLocalizedString(@"Бонусная сцена до титров", nil);
  } else {
    return nil;
  }
}

- (NSString *)subtitle {
  NSMutableArray *subtitleComps = [NSMutableArray new];
  if (self.age >= 0) {
    [subtitleComps addObject:[NSString stringWithFormat:@"%@+", @(self.age)]];
  }
  if (self.genre) {
    [subtitleComps addObject:self.genre[0]];
  }
  if (self.runtime > 0) {
    [subtitleComps addObject:[self runtimeString]];
  }
  if (subtitleComps.count > 0) {
    return [subtitleComps componentsJoinedByString:@" | "];
  } else {
    return nil;
  }
}

- (void)processShowtimes {
  NSMutableDictionary *sortedShowtimesDict = [NSMutableDictionary new];
  self.groupedShowtimes = [NSMutableDictionary new];
  for (id theatreId in self.showtimes) {
    NSArray *showtimesArray = self.showtimes[theatreId];
    if (showtimesArray.count > 0) {
      NSArray *sortedShowtimesArray = [SEADataManager showtimesSortedByTime:[[NSSet setWithArray:self.showtimes[theatreId]] allObjects]];
      sortedShowtimesDict[theatreId] = sortedShowtimesArray;
      if (!self.groupedShowtimes[theatreId]) {
        self.groupedShowtimes[theatreId] = [NSMutableDictionary new];
      }
      for (SEAShowtime *showtime in sortedShowtimesArray) {
        if (!self.groupedShowtimes[theatreId][[showtime dateString]]) {
          self.groupedShowtimes[theatreId][[showtime dateString]] = [NSMutableArray new];
        }
        [self.groupedShowtimes[theatreId][[showtime dateString]] addObject:showtime];
      }
    }
  }
  _showtimes = sortedShowtimesDict;
}

- (NSArray *)showtimesForTheatreId:(NSString *)theatreId {
  return self.groupedShowtimes[theatreId][[[SEADataManager sharedInstance].dateFormatter stringFromDate:[SEADataManager sharedInstance].selectedDate]];
}

- (CGFloat)averageRating {
  if (_averageRatingNumber) {
    return (CGFloat)[_averageRatingNumber doubleValue];
  }
  NSArray *ratings = self.ratings;
  if (ratings.count > 0) {
    CGFloat averageRating = 0;
    CGFloat count = 0;
    for (NSUInteger i = 0; i < ratings.count; i++) {
      if ([ratings[i] intValue] != 0) {
        count++;
        if (i == SEARatingSourceKinopoisk || i == SEARatingSourceIMDB) {
          averageRating += [ratings[i] floatValue] * 10;
        } else {
          averageRating += [ratings[i] floatValue];
        }
      }
    }
    if (count > 0) {
      _averageRatingNumber = @(averageRating / count);
    } else {
      _averageRatingNumber = @0;
    }
  } else {
    _averageRatingNumber = @0;
  }
  return (CGFloat)[_averageRatingNumber doubleValue];
}

- (BOOL)isPlaying {
  if (self.date) {
    if ([self.date compare:[NSDate date]] == NSOrderedDescending) {
      return NO;
    }
  }
  return YES;
}

- (NSAttributedString *)highlightString:(NSString *)string inRange:(NSRange)range {
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:@{
                                                   NSForegroundColorAttributeName : [UIColor whiteColor],
                                                   NSFontAttributeName : [UIFont regularFontWithSize:[UIFont mediumTextFontSize]]
                                                 }];
  [attributedString addAttribute:NSForegroundColorAttributeName value:self.backdrop.colors[kBackdropTextColorKey] range:range];
  [attributedString addAttribute:NSFontAttributeName value:[UIFont boldFontWithSize:[UIFont mediumTextFontSize]] range:range];
  return attributedString;
}

- (NSInteger)daysToDate {
  NSDate *fromDate;
  NSDate *toDate;
  NSCalendar *calendar = [NSCalendar currentCalendar];
  [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:nil forDate:[NSDate date]];
  [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:nil forDate:self.date];
  NSDateComponents *difference = [calendar components:NSCalendarUnitDay fromDate:fromDate toDate:toDate options:0];
  return [difference day];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.id) forKey:kIdKey];
  [coder encodeObject:self.title forKey:kMovieTitleKey];
  [coder encodeObject:self.originalTitle forKey:kMovieOriginalTitleKey];
  [coder encodeObject:@(self.year) forKey:kMovieYearKey];
  [coder encodeObject:self.ratings[SEARatingSourceKinopoisk] forKey:kMovieKpRatingKey];
  [coder encodeObject:self.ratings[SEARatingSourceIMDB] forKey:kMovieImdbRatingKey];
  [coder encodeObject:self.ratings[SEARatingSourceRTCritics] forKey:kMovieRtCriticsKey];
  [coder encodeObject:self.ratings[SEARatingSourceRTAudience] forKey:kMovieRtAudienceKey];
  [coder encodeObject:self.genre forKey:kMovieGenreKey];
  [coder encodeObject:@(self.runtime) forKey:kMovieRuntimeKey];
  [coder encodeObject:@(self.age) forKey:kMovieAgeKey];
  [coder encodeObject:self.synopsis forKey:kMovieSynopsisKey];
  [coder encodeObject:self.poster forKey:kMoviePosterKey];
  [coder encodeObject:self.trailerId forKey:kMovieTrailerIdKey];
  [coder encodeObject:self.director forKey:kMovieDirectorKey];
  [coder encodeObject:self.script forKey:kMovieScriptKey];
  [coder encodeObject:self.cast forKey:kMovieCastKey];
  [coder encodeObject:@(self.popularity) forKey:kMoviePopularityKey];
  [coder encodeObject:self.date forKey:kMovieDateKey];
  [coder encodeObject:@(self.featured) forKey:kMovieFeaturedKey];
  [coder encodeObject:self.stills forKey:kMovieStillsKey];
  [coder encodeObject:self.reviews forKey:kMovieReviewsKey];
  [coder encodeObject:self.backdrop forKey:kBackdropKey];
  [coder encodeObject:self.showtimes forKey:kShowtimesKey];
}

@end
