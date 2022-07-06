#import "SEALocationManager.h"

#import "AYMacros.h"
#import "CLLocation+SEAHelpers.h"
#import "LMAddress.h"
#import "LMGeocoder.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEATheatre.h"

@interface SEALocationManager ()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation SEALocationManager

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.locationManager = [CLLocationManager new];
  self.locationManager.delegate = self;
  self.locationManager.distanceFilter = kCLDistanceFilterNone;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

  return self;
}

+ (SEALocationManager *)sharedInstance {
  static SEALocationManager *sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    sharedInstance = [SEALocationManager new];
  });
  return sharedInstance;
}

#pragma mark Public

- (void)restoreCity {
  NSString *cachedCity = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kCityNameKey];
  self.currentCity = cachedCity;
}

- (RACSignal *)getCurrentCity {
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if (self.currentCity) {
      [subscriber sendNext:self.currentCity];
      [subscriber sendCompleted];
      return nil;
    }
#ifndef SNAPSHOT
    [[[[self getCurrentLocation] then:^RACSignal *{
      if (self.currentLocation) {
        return [[[self reverseGeocodeLocation:self.currentLocation] map:^id (LMAddress *address) {
          return address.locality;
        }] doNext:^(NSString *city) {
          self.currentCity = self.currentCity ? : city;
          self.actualCity = city;
        }];
      } else {
        return [RACSignal empty];
      }
    }] catchTo:[RACSignal empty]] subscribe:subscriber];
#else
    self.currentCity = @"Алматы";
    [subscriber sendNext:self.currentCity];
    [subscriber sendCompleted];
#endif
    return nil;
  }] finally:^{
    NSString *cachedCity = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kCityNameKey];
    if (![[SEADataManager sharedInstance] citySupported] && cachedCity) {
      self.currentCity = cachedCity;
    }
  }];
}

- (CLLocationDistance)distanceFromLocation:(CLLocation *)location {
  if (!self.currentLocation) {
    return -1;
  }
  return [self.currentLocation distanceFromLocation:location];
}

#pragma mark Private

- (RACSignal *)getCurrentLocation {
  if (self.currentLocation) {
    return [RACSignal return :self.currentLocation];
  }
  return [[[self requestWhenInUseAuthorization] then:^RACSignal *{
    return [self updateCurrentLocation];
  }] doNext:^(CLLocation *location) {
    self.currentLocation = location;
  }];
}

- (RACSignal *)requestWhenInUseAuthorization {
  if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
    return [RACSignal return :@YES];
  }
  if ([self needsAuthorization]) {
    [self.locationManager requestWhenInUseAuthorization];
    return [self didAuthorize];
  } else {
    return [self authorized];
  }
}

- (RACSignal *)updateCurrentLocation {
  RACSignal *currentLocationUpdated = [[[self didUpdateLocations] map:^id (NSArray *locations) {
    return locations.lastObject;
  }] filter:^BOOL (CLLocation *location) {
    return !location.isStale;
  }];

  RACSignal *locationUpdateFailed = [[[self didFailWithError] map:^id (NSError *error) {
    return [RACSignal error:error];
  }] switchToLatest];

  return [[[[RACSignal merge:@[currentLocationUpdated, locationUpdateFailed]] take:1] initially:^{
    [self.locationManager startUpdatingLocation];
  }] finally:^{
    [self.locationManager stopUpdatingLocation];
  }];
}

- (RACSignal *)reverseGeocodeLocation:(CLLocation *)location {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[LMGeocoder sharedInstance] reverseGeocodeCoordinate:location.coordinate service:kLMGeocoderGoogleService completionHandler:^(LMAddress *address, NSError *error) {
      if (address && !error) {
        [subscriber sendNext:address];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (BOOL)authorizationStatusEqualTo:(CLAuthorizationStatus)status {
  return [CLLocationManager authorizationStatus] == status;
}

- (BOOL)needsAuthorization {
  return [self authorizationStatusEqualTo:kCLAuthorizationStatusNotDetermined];
}

- (RACSignal *)didAuthorize {
  return [[[[self didChangeAuthorizationStatus] ignore:@(kCLAuthorizationStatusNotDetermined)] map:^id (NSNumber *status) {
    return @(status.integerValue == kCLAuthorizationStatusAuthorizedWhenInUse);
  }] take:1];
}

- (RACSignal *)authorized {
  BOOL authorized = [self authorizationStatusEqualTo:kCLAuthorizationStatusAuthorizedWhenInUse] || [self authorizationStatusEqualTo:kCLAuthorizationStatusAuthorizedAlways];
  return [RACSignal return :@(authorized)];
}

#pragma mark CLLocationManagerDelegate

- (RACSignal *)didUpdateLocations {
  return [[self rac_signalForSelector:@selector(locationManager:didUpdateLocations:) fromProtocol:@protocol(CLLocationManagerDelegate)] reduceEach:^id (CLLocationManager *manager, NSArray *locations) {
    return locations;
  }];
}

- (RACSignal *)didFailWithError {
  return [[self rac_signalForSelector:@selector(locationManager:didFailWithError:) fromProtocol:@protocol(CLLocationManagerDelegate)] reduceEach:^id (CLLocationManager *manager, NSError *error) {
    return error;
  }];
}

- (RACSignal *)didChangeAuthorizationStatus {
  return [[self rac_signalForSelector:@selector(locationManager:didChangeAuthorizationStatus:) fromProtocol:@protocol(CLLocationManagerDelegate)] reduceEach:^id (CLLocationManager *manager, NSNumber *status) {
    return status;
  }];
}

@end
