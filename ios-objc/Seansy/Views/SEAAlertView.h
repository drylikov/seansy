//
//  Copyright (c) 2014 AnyKey Entertainment, 2015 Ayan Yenbekbay.
//

#import "SEAConstants.h"

@interface SEAAlertView : UIView

#pragma mark Properties

@property (copy, nonatomic) SEADismissHandler dismissHandler;
@property (copy, nonatomic) NSString *body;
@property (copy, nonatomic) NSString *closeButtonTitle;
@property (copy, nonatomic) NSString *title;
@property (nonatomic) BOOL dismissOnTapOutside;
@property (nonatomic) NSDictionary *bodyTextAttributes;
@property (nonatomic) NSDictionary *buttonTextAttributes;
@property (nonatomic) NSDictionary *titleTextAttributes;
@property (nonatomic) NSTimeInterval animationDuration;
@property (nonatomic) UIColor *contentViewColor;
@property (nonatomic) UIImage *image;

#pragma mark Methods

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body;
- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body closeButtonTitle:(NSString *)closeButtonTitle;
- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body closeButtonTitle:(NSString *)closeButtonTitle handler:(SEADismissHandler)handler;
- (instancetype)initWithView:(UIView *)view closeButtonTitle:(NSString *)closeButtonTitle;
- (instancetype)initWithView:(UIView *)view closeButtonTitle:(NSString *)closeButtonTitle handler:(SEADismissHandler)handler;
- (void)addButtonWithTitle:(NSString *)title handler:(SEADismissHandler)handler;
- (void)show;
- (void)dismissAnimated:(BOOL)animated;

@end
