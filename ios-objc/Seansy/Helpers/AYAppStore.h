#import <UIKit/UIKit.h>

@interface AYAppStore : NSObject

+ (void)openAppStoreReviewForApp:(NSString *)appId;
+ (void)openAppStoreForApp:(NSString *)appId;
+ (void)openAppStoreForMyApps;

@end
