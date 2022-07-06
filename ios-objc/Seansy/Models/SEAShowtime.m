#import "SEAShowtime.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "UIFont+SEASizes.h"
#import "Secrets.h"

#define DISABLE_TICKETON

static NSString *const kShowtimeTimeKey = @"time";
static NSString *const kShowtimeFormatKey = @"format";
static NSString *const kShowtimeLanguageKey = @"language";
static NSString *const kShowtimePricesKey = @"prices";
static NSString *const kMovieIdKey = @"movieId";
static NSString *const kTheatreIdKey = @"theatreId";
static NSString *const kShowtimeDateKey = @"date";
static NSString *const kShowtimeTicketonIdKey = @"ticketonId";

static NSString *const kTicketonRootUrl = @"https://m.ticketon.kz";

@implementation SEAShowtime

#pragma mark Initialization

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (!self) {
    return nil;
  }

  _time = [[SEADataManager sharedInstance] timeIntervalFromString:[self stringFromDictionary:dictionary key:kShowtimeTimeKey]];
  _theatreId = [[self stringFromDictionary:dictionary key:kTheatreIdKey] integerValue];
  _movieId = [[self stringFromDictionary:dictionary key:kMovieIdKey] integerValue];
  _format = [self stringFromDictionary:dictionary key:kShowtimeFormatKey];
  _language = [self stringFromDictionary:dictionary key:kShowtimeLanguageKey];
  NSString *pricesString = [self stringFromDictionary:dictionary key:kShowtimePricesKey] ? : @"";
  NSError *pricesError = nil;
  _prices = [NSJSONSerialization JSONObjectWithData:[pricesString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&pricesError];
  _date = [[[SEADataManager sharedInstance].dateFormatter dateFromString:[self stringFromDictionary:dictionary key:kShowtimeDateKey]] dateByAddingTimeInterval:self.time];
#ifndef DISABLE_TICKETON
  _ticketonId = [self stringFromDictionary:dictionary key:kShowtimeTicketonIdKey];
#endif

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _time = [[decoder decodeObjectForKey:kShowtimeTimeKey] doubleValue];
  _format = [decoder decodeObjectForKey:kShowtimeFormatKey];
  _language = [decoder decodeObjectForKey:kShowtimeLanguageKey];
  _prices = [decoder decodeObjectForKey:kShowtimePricesKey];
  _movieId = [[decoder decodeObjectForKey:kMovieIdKey] integerValue];
  _theatreId = [[decoder decodeObjectForKey:kTheatreIdKey] integerValue];
  _date = [decoder decodeObjectForKey:kShowtimeDateKey];
  _ticketonId = [decoder decodeObjectForKey:kShowtimeTicketonIdKey];

  return self;
}

#pragma mark NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: Time=%@, Date:%@, Format:%@, Language:%@, Prices:%@, Ticketon ID:%@\n>", self.class, [self timeString], [self dateString], self.format, self.language, self.prices, self.ticketonId];
}

- (BOOL)isEqual:(id)object {
  if ([super isEqual:object]) {
    return YES;
  }
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  SEAShowtime *other = object;
  return self.date == other.date && [self.format isEqualToString:other.format] && self.movieId == other.movieId && self.theatreId == other.movieId;
}

#pragma mark Public

- (NSString *)timeString {
  return [self timeString:self.time];
}

- (NSString *)timeString:(NSTimeInterval)interval {
  int time = (int)interval;
  int minutes = (time / 60) % 60;
  int hours = (time / 3600);
  return [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
}

- (NSString *)dateString {
  return [[SEADataManager sharedInstance].dateFormatter stringFromDate:self.date];
}

- (BOOL)hasPassed {
  return [SEADataManager hasPassed:self.date];
}

- (NSString *)formatString {
  if ([self.format rangeOfString:@"3D"].length != 0) {
    return @"3D";
  } else {
    return self.format;
  }
}

- (NSAttributedString *)attributedSummaryString {
  NSMutableAttributedString *showtimeText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [self timeString]] attributes:@{ NSFontAttributeName : [UIFont timeFontWithSize:[UIFont largeTextFontSize]] }];

  if (self.format) {
    [showtimeText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", [self formatString]] attributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont smallTextFontSize]] }]];
  }
  if ([self ticketonUrl]) {
    NSTextAttachment *textAttachment = [NSTextAttachment new];
    textAttachment.image = [[UIImage imageNamed:@"TicketIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    NSAttributedString *ticketonIcon = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [showtimeText appendAttributedString:[[NSAttributedString alloc] initWithString:self.format ? @" " : @"\n" attributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont smallTextFontSize]] }]];
    [showtimeText appendAttributedString:ticketonIcon];
  }
  return showtimeText;
}

- (NSAttributedString *)attributedSummaryInlineString {
  NSDictionary *attributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont smallTextFontSize]]
  };
  NSMutableAttributedString *showtimeText = [[NSMutableAttributedString alloc] initWithString:[[SEADataManager sharedInstance] theatreForId:self.theatreId].name attributes:attributes];
  if (self.format) {
    [showtimeText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@)", self.formatString] attributes:attributes]];
  }
  if ([self ticketonUrl]) {
    [showtimeText appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:attributes]];
    NSTextAttachment *textAttachment = [NSTextAttachment new];
    textAttachment.image = [[UIImage imageNamed:@"TicketIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    NSAttributedString *ticketonIcon = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [showtimeText appendAttributedString:ticketonIcon];
  }
  return showtimeText;
}

- (NSAttributedString *)attributedDetailsString {
  NSDictionary *attributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont mediumTextFontSize]]
  };
  NSDictionary *metaAttributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont mediumTextFontSize]],
    NSForegroundColorAttributeName : [UIColor colorWithWhite:0 alpha:kSecondaryTextAlpha]
  };
  NSMutableAttributedString *attributesString = [[NSMutableAttributedString alloc] initWithString:@""];
  NSString *adultPrice = self.prices[@"adult"];
  NSString *childrenPrice = self.prices[@"children"];
  NSString *studentPrice = self.prices[@"student"];
  NSString *vipPrice = self.prices[@"vip"];
  NSString *time;
  SEAMovie *movie = [[SEADataManager sharedInstance] movieForId:self.movieId];

  if (movie.runtime > 0) {
    NSTimeInterval end = (int)(((self.time + movie.runtime) / 60 + 10) / 10 + 0.5) * 600;
    if (end > 24 * 3600) {
      end -= 24 * 3600;
    }
    time = [NSString stringWithFormat:@"%@ ~ %@", [self timeString], [self timeString:end]];
  }

  if (adultPrice.length > 0) {
    [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"взрослый: ", nil) attributes:attributes]];
    [attributesString appendAttributedString:[self boldPrice:adultPrice]];
  }

  if (childrenPrice.length > 0) {
    if (attributesString.length > 0) {
      [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"детский: ", nil) attributes:attributes]];
    [attributesString appendAttributedString:[self boldPrice:childrenPrice]];
  }

  if (studentPrice.length > 0) {
    if (attributesString.length > 0) {
      [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"студенческий: ", nil) attributes:attributes]];
    [attributesString appendAttributedString:[self boldPrice:studentPrice]];
  }

  if (vipPrice.length > 0) {
    if (attributesString.length > 0) {
      [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:@"VIP: " attributes:attributes]];
    [attributesString appendAttributedString:[self boldPrice:vipPrice]];
  }

  if (time) {
    if (attributesString.length > 0) {
      [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:time attributes:metaAttributes]];
    if (self.language) {
      [attributesString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@. яз.)", self.language] attributes:metaAttributes]];
    }
  }

  return attributesString;
}

- (NSAttributedString *)boldPrice:(NSString *)string {
  NSMutableAttributedString *boldPrice = [[NSMutableAttributedString alloc] initWithString:string attributes:@{ NSFontAttributeName : [UIFont boldFontWithSize:[UIFont mediumTextFontSize]] }];
  [boldPrice appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"тг", nil) attributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont mediumTextFontSize]] }]];
  return boldPrice;
}

- (NSURL *)ticketonUrl {
  if (!self.ticketonId || self.ticketonId.length == 0 || [self hasPassed]) {
    return nil;
  }
  NSURL *ticketonUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/show/%@?token=%@", kTicketonRootUrl, self.ticketonId, kTicketonToken]];
  return ticketonUrl;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.time) forKey:kShowtimeTimeKey];
  [coder encodeObject:self.format forKey:kShowtimeFormatKey];
  [coder encodeObject:self.language forKey:kShowtimeLanguageKey];
  [coder encodeObject:self.prices forKey:kShowtimePricesKey];
  [coder encodeObject:@(self.movieId) forKey:kMovieIdKey];
  [coder encodeObject:@(self.theatreId) forKey:kTheatreIdKey];
  [coder encodeObject:self.date forKey:kShowtimeDateKey];
  [coder encodeObject:self.ticketonId forKey:kShowtimeTicketonIdKey];
}

@end
