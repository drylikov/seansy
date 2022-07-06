//
//  Copyright (c) 2015 Román Aguirre, 2015 Ayan Yenbekbay.
//

#import <UIKit/UIKit.h>

@interface DRViewSlideAction : NSObject

typedef NS_ENUM(NSUInteger, DRViewSlideActionBehavior) {
	DRViewSlideActionPullBehavior,
	DRViewSlideActionPushBehavior,
};

typedef void(^DRViewSlideActionBlock)();
typedef void(^DRViewSlideActionStateBlock)(DRViewSlideAction *action, BOOL active);

#pragma mark Properties

@property (nonatomic) DRViewSlideActionBehavior behavior;
@property (nonatomic, readonly) CGFloat fraction;
@property (nonatomic) CGFloat elasticity;
@property (nonatomic) UIColor *activeBackgroundColor;
@property (nonatomic) UIColor *inactiveBackgroundColor;
@property (nonatomic) UIColor *activeColor;
@property (nonatomic) UIColor *inactiveColor;
@property (nonatomic) UIImage *icon;
@property (nonatomic) CGFloat iconMargin;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) DRViewSlideActionBlock willTriggerBlock;
@property (nonatomic, copy) DRViewSlideActionBlock didTriggerBlock;
@property (nonatomic, copy) DRViewSlideActionStateBlock didChangeStateBlock;

#pragma mark Methods

+ (instancetype)actionForFraction:(CGFloat)fraction;

@end
