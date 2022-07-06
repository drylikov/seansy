#import "SEABackdrop.h"
#import "SEAModel.h"
#import <CoreLocation/CoreLocation.h>

@interface SEATheatre : SEAModel <NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSInteger id;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *city;
@property (nonatomic, readonly) NSString *address;
@property (nonatomic, readonly) NSString *phone;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) SEABackdrop *backdrop;
@property (nonatomic, getter = isFavorite) BOOL favorite;

#pragma mark Methods

- (instancetype)initWithDictionary:(NSDictionary *)theatreDictionary;
- (NSString *)distance;
- (NSString *)formattedPhone;
- (NSString *)subtitle;
- (void)call;
- (void)openDirections;

@end
