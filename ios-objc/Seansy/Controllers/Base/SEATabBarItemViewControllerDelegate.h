#import <ReactiveCocoa/ReactiveCocoa.h>

@protocol SEATabBarItemViewControllerDelegate <NSObject>
@required
- (RACSignal *)refresh;
- (void)restoreBars;
@end
