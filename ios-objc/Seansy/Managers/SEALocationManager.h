#import <CoreLocation/CoreLocation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

/**
 *  Provides an interface for getting current location and calculating distances.
 */
@interface SEALocationManager : NSObject <CLLocationManagerDelegate>

#pragma mark Methods

/**
 *  Restores the cached city.
 */
- (void)restoreCity;
/**
 *  Access the shared location manager object.
 *
 *  @return The shared location manager object.
 */
+ (SEALocationManager *)sharedInstance;
/**
 *  Fetches the current city by location.
 */
- (RACSignal *)getCurrentCity;
/**
 *  Calculates the distance from the given location to the currnet location.
 *
 *  @param location Location to calculate the distance to.
 *
 *  @return Distance from the current location to the given location.
 */
- (CLLocationDistance)distanceFromLocation:(CLLocation *)location;

#pragma mark Properties

/**
 *  Current geographical location of the user.
 */
@property (nonatomic) CLLocation *currentLocation;
/**
 *  User's active city, initially given by the user's current location. Can be set by the location selector.
 */
@property (nonatomic) NSString *currentCity;
/**
 *  City given by the user's geographical position.
 */
@property (nonatomic) NSString *actualCity;

@end
