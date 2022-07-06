#import "SEADataManager.h"

@interface SEANavigationBarTitleView : UIView

#pragma mark Properties

@property (copy, nonatomic) NSString *city;
@property (nonatomic) SEAShowtimesDate dateIndex;

#pragma mark Methods

- (void)pointArrowUp;
- (void)pointArrowDown;

@end
