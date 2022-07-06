//
//  Copyright (c) 2014 Callum Boddy, 2015 Ayan Yenbekbay.
//

#import "SEASplashView.h"

@interface SEASplashView ()

@property (nonatomic) UIImage *iconImage;
@property (nonatomic) UIImageView *iconImageView;

@end

@implementation SEASplashView

#pragma mark Initialization

- (instancetype)initWithIconImage:(UIImage *)icon backgroundColor:(UIColor *)backgroundColor iconColor:(UIColor *)iconColor iconSize:(CGSize)iconSize {
  self = [super initWithFrame:[UIScreen mainScreen].bounds];
  if (!self) {
    return nil;
  }

  self.backgroundColor = backgroundColor;

  self.animationDuration = NSNotFound;
  self.iconImageView = [[UIImageView alloc] initWithImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
  self.iconImageView.tintColor = iconColor;
  self.iconImageView.frame = CGRectMake(0, 0, iconSize.width, iconSize.height);
  self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.iconImageView.center = self.center;

  [self addSubview:self.iconImageView];

  return self;
}

#pragma mark Getters & setters

- (CGFloat)animationDuration {
  if (_animationDuration == NSNotFound) {
    _animationDuration = 1;
  }

  return _animationDuration;
}

- (CAAnimation *)iconAnimation {
  if (!_iconAnimation) {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.values = @[@1, @0.9f, @300];
    animation.keyTimes = @[@0, @0.4f, @1];
    animation.duration = self.animationDuration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunctions = @[
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]
    ];

    _iconAnimation = animation;
  }

  return _iconAnimation;
}

#pragma mark Public

- (void)startAnimation {
  [self startAnimationWithCompletionHandler:nil];
}

- (void)startAnimationWithCompletionHandler:(void (^)())completionHandler {
  __block __weak typeof(self) weakSelf = self;

  CGFloat shrinkDuration = self.animationDuration * 0.3f;
  CGFloat growDuration = self.animationDuration * 0.7f;

  [UIView animateWithDuration:shrinkDuration delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.75f, 0.75f);
    weakSelf.iconImageView.transform = scaleTransform;
  } completion:^(BOOL finishedFirst) {
    [UIView animateWithDuration:growDuration animations:^{
      CGAffineTransform scaleTransform = CGAffineTransformMakeScale(20, 20);
      weakSelf.iconImageView.transform = scaleTransform;
      weakSelf.alpha = 0;
    } completion:^(BOOL finishedSecond) {
      [weakSelf removeFromSuperview];
      if (completionHandler) {
        completionHandler();
      }
    }];
  }];
}

@end
