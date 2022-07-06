//
//  Copyright (c) 2014 kishikawa katsumi, 2015 Ayan Yenbekbay.
//

#import <UIKit/UIKit.h>

@interface SEAProgressView : UIView

#pragma mark Properties

@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) CGFloat progress;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat spinnerHeight;
@property (nonatomic) UIColor *tintColor;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic, getter = isIndeterminate) BOOL indeterminate;
@property (nonatomic, getter = isVisible) BOOL visible;

#pragma mark Methods

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
- (void)performFinishAnimationWithDelay:(CGFloat)delay dismissHandler:(void (^)())dismissHandler;
- (void)performFinishAnimation;

@end
