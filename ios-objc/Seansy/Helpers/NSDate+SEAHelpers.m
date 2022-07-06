#import "NSDate+SEAHelpers.h"

#import "NSString+SEAHelpers.h"

@implementation NSDate (SEAHelpers)

+ (instancetype)dateForHour:(NSInteger)hour {
  NSDate *date = [NSDate date];
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  NSCalendarUnit preservedComponents = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  NSDateComponents *components = [calendar components:preservedComponents fromDate:date];
  NSDate *dateForHour = [[calendar dateFromComponents:components] dateByAddingTimeInterval:60 * 60 * hour];
  NSInteger currentHour = [[calendar components:NSCalendarUnitHour fromDate:date] hour];
  if (currentHour >= hour) {
    dateForHour = [dateForHour dateByAddingTimeInterval:60 * 60 * 24];
  }
  return dateForHour;
}

- (NSString *)timeAgo {
  NSDate *now = [NSDate date];
  NSInteger deltaSeconds = (NSInteger)fabs([self timeIntervalSinceDate:now]);
  NSInteger deltaMinutes = deltaSeconds / 60;
  NSInteger minutes;

  if (deltaSeconds < 5) {
    return @"Только что";
  } else if (deltaSeconds < 60) {
    return [NSString stringWithFormat:@"%@ %@ назад", @(deltaSeconds), [NSString getNumEnding:deltaSeconds endings:@[@"секунду", @"секунды", @"секунд"]]];
  } else if (deltaSeconds < 120) {
    return @"Минуту назад";
  } else if (deltaMinutes < 60) {
    return [NSString stringWithFormat:@"%@ %@ назад", @(deltaMinutes), [NSString getNumEnding:deltaMinutes endings:@[@"минуту", @"минуты", @"минут"]]];
  } else if (deltaMinutes < 120) {
    return @"Час назад";
  } else if (deltaMinutes < (24 * 60)) {
    minutes = (NSInteger)floor(deltaMinutes / 60);
    return [NSString stringWithFormat:@"%@ %@ назад", @(minutes), [NSString getNumEnding:minutes endings:@[@"час", @"часа", @"часов"]]];
  } else if (deltaMinutes < (24 * 60 * 2)) {
    return @"Вчера";
  } else if (deltaMinutes < (24 * 60 * 7)) {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24));
    return [NSString stringWithFormat:@"%@ %@ назад", @(minutes), [NSString getNumEnding:minutes endings:@[@"день", @"дня", @"дней"]]];
  } else if (deltaMinutes < (24 * 60 * 14)) {
    return @"Неделю назад";
  } else if (deltaMinutes < (24 * 60 * 31)) {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24 * 7));
    return [NSString stringWithFormat:@"%@ %@ назад", @(minutes), [NSString getNumEnding:minutes endings:@[@"неделю", @"недели", @"недель"]]];
  } else if (deltaMinutes < (24 * 60 * 61)) {
    return @"Месяц назад";
  } else if (deltaMinutes < (24 * 60 * 365.25)) {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24 * 30));
    return [NSString stringWithFormat:@"%@ %@ назад", @(minutes), [NSString getNumEnding:minutes endings:@[@"месяц", @"месяца", @"месяцев"]]];
  } else if (deltaMinutes < (24 * 60 * 731)) {
    return @"Год назад";
  } else {
    minutes = (NSInteger)floor(deltaMinutes / (60 * 24 * 365));
    return [NSString stringWithFormat:@"%@ %@ назад", @(minutes), [NSString getNumEnding:minutes endings:@[@"год", @"года", @"лет"]]];
  }
}

@end
