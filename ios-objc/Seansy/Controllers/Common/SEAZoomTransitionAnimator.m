#import "SEAZoomTransitionAnimator.h"

#import "UIView+AYUtils.h"

@interface SEAZoomTransitionAnimator ()

@property (nonatomic) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic) UIBezierPath *circleMaskPathInitial;
@property (nonatomic) UIBezierPath *circleMaskPathFinal;

@end

@implementation SEAZoomTransitionAnimator

static const NSTimeInterval kForwardAnimationDuration = 0.25f;
static const NSTimeInterval kBackAnimationDuration = 0.25f;

#pragma mark UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
  if (self.goingForward) {
    return kForwardAnimationDuration;
  } else {
    return kBackAnimationDuration;
  }
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  self.transitionContext = transitionContext;
  // Setup for animation transition
  UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIView *containerView = [transitionContext containerView];
  if (self.goingForward) {
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];
  } else {
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
  }

  // Transition source of image to move me to add to the last
  UIImageView *sourceImageView = [self.sourceTransition transitionSourceImageView];
  [containerView addSubview:sourceImageView];

  if ([self.destinationTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [self.destinationTransition respondsToSelector:@selector(zoomTransitionAnimatorWillStartTransition:)]) {
    [self.destinationTransition zoomTransitionAnimatorWillStartTransition:self];
  }
  if ([self.sourceTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [self.sourceTransition respondsToSelector:@selector(zoomTransitionAnimatorWillStartTransition:)]) {
    [self.sourceTransition zoomTransitionAnimatorWillStartTransition:self];
  }

  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
  maskLayerAnimation.timingFunction = [CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  maskLayerAnimation.delegate = self;
  CGRect destinationImageViewFrame = [self.destinationTransition transitionDestinationImageViewFrame];

  if (self.goingForward) {
    CGRect sourceImageViewCircle = CGRectMake(sourceImageView.left, sourceImageView.top + (sourceImageView.height - sourceImageView.width) / 2, sourceImageView.width, sourceImageView.width);
    self.circleMaskPathInitial = [UIBezierPath bezierPathWithOvalInRect:sourceImageViewCircle];
    CGPoint extremePoint = CGPointMake(MAX(CGRectGetMidX(destinationImageViewFrame), (toVC.view.width - CGRectGetMidX(destinationImageViewFrame))), MAX(CGRectGetMidY(destinationImageViewFrame), (toVC.view.height - CGRectGetMidY(destinationImageViewFrame))));
    CGFloat radius = (CGFloat)sqrt(extremePoint.x * extremePoint.x + extremePoint.y * extremePoint.y);
    self.circleMaskPathFinal = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(destinationImageViewFrame, -radius, -radius)];

    maskLayer.path = self.circleMaskPathFinal.CGPath;
    toVC.view.layer.mask = maskLayer;

    maskLayerAnimation.fromValue = (__bridge id)((self.circleMaskPathInitial.CGPath));
    maskLayerAnimation.toValue = (__bridge id)(self.circleMaskPathFinal.CGPath);
    maskLayerAnimation.duration = kForwardAnimationDuration;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"path"];

    [UIView animateWithDuration:kForwardAnimationDuration delay:0 usingSpringWithDamping:transitionContext.isInteractive ? 1 : 0.75f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      sourceImageView.frame = destinationImageViewFrame;
    } completion:^(BOOL finished) {
      [sourceImageView removeFromSuperview];
      if ([self.destinationTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [self.destinationTransition respondsToSelector:@selector(zoomTransitionAnimator:didCompleteTransition:animatingSourceImageView:)]) {
        [self.destinationTransition zoomTransitionAnimator:self didCompleteTransition:![transitionContext transitionWasCancelled] animatingSourceImageView:sourceImageView];
      }
    }];
  } else {
    CGPoint extremePoint = CGPointMake(MAX(sourceImageView.centerX, fromVC.view.width - sourceImageView.centerX), MAX(sourceImageView.centerY, fromVC.view.height - sourceImageView.centerY));
    CGFloat radius = (CGFloat)sqrt(extremePoint.x * extremePoint.x + extremePoint.y * extremePoint.y);
    self.circleMaskPathInitial = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(sourceImageView.frame, -radius, -radius)];
    CGRect destinationImageViewCircle = CGRectMake(CGRectGetMinX(destinationImageViewFrame), CGRectGetMinY(destinationImageViewFrame) + (CGRectGetHeight(destinationImageViewFrame) - CGRectGetWidth(destinationImageViewFrame)) / 2, CGRectGetWidth(destinationImageViewFrame), CGRectGetWidth(destinationImageViewFrame));
    self.circleMaskPathFinal = [UIBezierPath bezierPathWithOvalInRect:destinationImageViewCircle];

    maskLayer.path = self.circleMaskPathFinal.CGPath;
    fromVC.view.layer.mask = maskLayer;

    maskLayerAnimation.fromValue = (__bridge id)((self.circleMaskPathInitial.CGPath));
    maskLayerAnimation.toValue = (__bridge id)(self.circleMaskPathFinal.CGPath);
    maskLayerAnimation.duration = kBackAnimationDuration;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"path"];

    [UIView animateWithDuration:kBackAnimationDuration delay:0 usingSpringWithDamping:transitionContext.isInteractive ? 1 : 0.75f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      sourceImageView.frame = [self.destinationTransition transitionDestinationImageViewFrame];
    } completion:^(BOOL finished) {
      [sourceImageView removeFromSuperview];
      if ([self.destinationTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [self.destinationTransition respondsToSelector:@selector(zoomTransitionAnimator:didCompleteTransition:animatingSourceImageView:)]) {
        [self.destinationTransition zoomTransitionAnimator:self didCompleteTransition:![self.transitionContext transitionWasCancelled] animatingSourceImageView:sourceImageView];
      }
      if ([self.sourceTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [self.sourceTransition respondsToSelector:@selector(zoomTransitionAnimator:didCompleteTransition:animatingSourceImageView:)]) {
        [self.sourceTransition zoomTransitionAnimator:self didCompleteTransition:![transitionContext transitionWasCancelled] animatingSourceImageView:sourceImageView];
      }
    }];
  }
}

#pragma mark CABasicAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  [self.transitionContext completeTransition:![self.transitionContext transitionWasCancelled]];
  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  maskLayer.path = [self.transitionContext transitionWasCancelled] ? self.circleMaskPathInitial.CGPath : self.circleMaskPathFinal.CGPath;
  if (self.goingForward) {
    [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view.layer.mask = nil;
  } else {
    [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].view.layer.mask = nil;
  }
}

@end
