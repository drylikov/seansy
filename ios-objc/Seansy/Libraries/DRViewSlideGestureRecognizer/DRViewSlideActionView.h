//
//  Copyright (c) 2015 Román Aguirre, 2015 Ayan Yenbekbay.
//

#import <UIKit/UIKit.h>

@class DRViewSlideAction;

@interface DRViewSlideActionView : UIView

#pragma mark Properties

@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, weak) DRViewSlideAction *action;

#pragma mark Methods

- (void)cellDidUpdatePosition:(UIView *)view;

@end
