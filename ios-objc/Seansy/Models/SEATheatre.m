#import "SEATheatre.h"

#import "LMAddress.h"
#import "LMGeocoder.h"
#import "SEAAlertView.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "UIImage+SEAHelpers.h"

static NSString *const kTheatreNameKey = @"name";
static NSString *const kTheatreCityKey = @"city";
static NSString *const kTheatreAddressKey = @"address";
static NSString *const kTheatreLocationKey = @"location";
static NSString *const kTheatrePhoneKey = @"phone";

@implementation SEATheatre

#pragma mark Initialization

- (instancetype)initWithDictionary:(NSDictionary *)theatreDictionary {
  self = [super init];
  if (!self) {
    return nil;
  }

  _id = [[self stringFromDictionary:theatreDictionary key:kIdKey] integerValue];
  _name = [self stringFromDictionary:theatreDictionary key:kTheatreNameKey];
  _city = [self stringFromDictionary:theatreDictionary key:kTheatreCityKey];
  _address = [self stringFromDictionary:theatreDictionary key:kTheatreAddressKey];
  _phone = [self stringFromDictionary:theatreDictionary key:kTheatrePhoneKey];
  NSString *locationString = [self stringFromDictionary:theatreDictionary key:kTheatreLocationKey] ? : @"";
  NSError *locationError = nil;
  NSDictionary *theatreLocationDictionary = [NSJSONSerialization JSONObjectWithData:[locationString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&locationError];
  _location = [[CLLocation alloc] initWithLatitude:[theatreLocationDictionary[@"lat"] doubleValue] longitude:[theatreLocationDictionary[@"lng"] doubleValue]];
  NSURL *theatreBackdropUrl = [NSURL URLWithString:[self stringFromDictionary:theatreDictionary key:kBackdropUrlKey]];
  _backdrop = [[SEABackdrop alloc] initWithUrl:theatreBackdropUrl];

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _id = [[decoder decodeObjectForKey:kIdKey] integerValue];
  _name = [decoder decodeObjectForKey:kTheatreNameKey];
  _city = [decoder decodeObjectForKey:kTheatreCityKey];
  _address = [decoder decodeObjectForKey:kTheatreAddressKey];
  NSDictionary *locationDictionary = [decoder decodeObjectForKey:kTheatreLocationKey];
  _location = [[CLLocation alloc] initWithLatitude:[locationDictionary[@"lat"] doubleValue] longitude:[locationDictionary[@"lng"] doubleValue]];
  _phone = [decoder decodeObjectForKey:kTheatrePhoneKey];
  _backdrop = [decoder decodeObjectForKey:kBackdropKey];

  return self;
}

#pragma mark Public

- (NSString *)distance {
  SEALocationManager *locationManager = [SEALocationManager sharedInstance];

  if (self.location && locationManager.actualCity && [locationManager.currentCity isEqualToString:locationManager.actualCity]) {
    CLLocationDistance distance = [locationManager distanceFromLocation:self.location];
    if (distance / 1000 < 1) {
      return [NSString stringWithFormat:NSLocalizedString(@"~%d м", @"~{distance to theatre} {meters}"), (int)(distance + 0.5)];
    } else {
      return [NSString stringWithFormat:NSLocalizedString(@"~%.2f км", @"~{distance to theatre} {kilometers}"), distance / 1000];
    }
  } else {
    return nil;
  }
}

- (NSString *)formattedPhone {
  NSCharacterSet *set = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
  NSString *phoneString = [[_phone componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
  switch (phoneString.length) {
    case 7: return [NSString stringWithFormat:@"%@-%@", [phoneString substringToIndex:3], [phoneString substringFromIndex:3]];
    case 10: return [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringToIndex:3], [phoneString substringWithRange:NSMakeRange(3, 3)], [phoneString substringFromIndex:6]];
    case 11: return [NSString stringWithFormat:@"+%@ (%@) %@-%@", [phoneString substringToIndex:1], [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringFromIndex:7]];
    case 12: return [NSString stringWithFormat:@"+%@ (%@) %@-%@", [phoneString substringToIndex:2], [phoneString substringWithRange:NSMakeRange(2, 3)], [phoneString substringWithRange:NSMakeRange(5, 3)], [phoneString substringFromIndex:8]];
    default: return nil;
  }
}

- (NSString *)subtitle {
  NSMutableArray *subtitleComps = [NSMutableArray new];
  if ([self distance]) {
    [subtitleComps addObject:[self distance]];
  }
  if (self.address) {
    [subtitleComps addObject:self.address];
  }
  if (subtitleComps.count > 0) {
    return [subtitleComps componentsJoinedByString:@" | "];
  } else {
    return nil;
  }
}

- (void)call {
#ifndef TARGET_IS_EXTENSION
  NSURL *phoneUrl = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", self.phone]];
  if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
    [[UIApplication sharedApplication] openURL:phoneUrl];
  } else {
    NSString *title = NSLocalizedString(@"Ошибка", nil);
    NSString *body = NSLocalizedString(@"Совершить вызов не получается.", nil);
    SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:title body:body];
    [alertView show];
  }
#endif
}

- (void)openDirections {
#ifndef TARGET_IS_EXTENSION
  SEALocationManager *locationManager = [SEALocationManager sharedInstance];
  if (locationManager.currentLocation) {
    CGFloat latFrom = (CGFloat)locationManager.currentLocation.coordinate.latitude;
    CGFloat lonFrom = (CGFloat)locationManager.currentLocation.coordinate.longitude;
    CGFloat latTo = (CGFloat)self.location.coordinate.latitude;
    CGFloat lonTo = (CGFloat)self.location.coordinate.longitude;
    NSURL *yandexNaviUrl = [NSURL URLWithString:[NSString stringWithFormat:@"yandexnavi://build_route_on_map?lat_from=%f&lon_from=%f&lat_to=%f&lon_to=%f&zoom=14", latFrom, lonFrom, latTo, lonTo]];
    if ([[UIApplication sharedApplication] canOpenURL:yandexNaviUrl]) {
      [[UIApplication sharedApplication] openURL:yandexNaviUrl];
    } else {
      NSURL *yandexMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"yandexmaps://build_route_on_map/?lat_from=%f&lon_from=%f&lat_to=%f&lon_to=%f&zoom=14", latFrom, lonFrom, latTo, lonTo]];
      if ([[UIApplication sharedApplication] canOpenURL:yandexMapsUrl]) {
        [[UIApplication sharedApplication] openURL:yandexMapsUrl];
      } else {
        NSURL *appStoreURL = [NSURL URLWithString:@"https://itunes.apple.com/kz/app/yandeks.navigator/id474500851?mt=8"];
        [[UIApplication sharedApplication] openURL:appStoreURL];
      }
    }
  } else {
    NSString *title = NSLocalizedString(@"Ошибка", nil);
    NSString *body = NSLocalizedString(@"Проверьте. что у вас включена служба геолокации.", nil);
    SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:title body:body];
    [alertView show];
  }
#endif /* ifndef TARGET_IS_EXTENSION */
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.id) forKey:kIdKey];
  [coder encodeObject:self.name forKey:kTheatreNameKey];
  [coder encodeObject:self.city forKey:kTheatreCityKey];
  [coder encodeObject:self.address forKey:kTheatreAddressKey];
  [coder encodeObject:@{
     @"lat" : @(self.location.coordinate.latitude),
     @"lng" : @(self.location.coordinate.longitude)
   } forKey:kTheatreLocationKey];
  [coder encodeObject:self.phone forKey:kTheatrePhoneKey];
  [coder encodeObject:self.backdrop forKey:kBackdropKey];
}

@end
