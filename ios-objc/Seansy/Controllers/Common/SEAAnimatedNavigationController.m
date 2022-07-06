#import "SEAAnimatedNavigationController.h"

#import "SEAMoviesPagerViewController.h"
#import "SEAShowtimesPagerViewController.h"
#import "SEAZoomTransitionAnimator.h"
#import "UIView+AYUtils.h"

@interface SEAAnimatedNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIPercentDrivenInteractiveTransition *interactivePopTransition;
@property (nonatomic) UIScreenEdgePanGestureRecognizer *popGestureRecognizer;
@property (nonatomic) NSMutableArray *disabledGestureRecognizers;

@end

@implementation SEAAnimatedNavigationController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.delegate = self;

  self.popGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePopRecognizer:)];
  self.popGestureRecognizer.edges = UIRectEdgeLeft;
  self.popGestureRecognizer.delegate = self;
  self.interactivePopGestureRecognizer.delegate = self;
  [self.view addGestureRecognizer:self.popGestureRecognizer];
}

- (void)handlePopRecognizer:(UIScreenEdgePanGestureRecognizer *)recognizer {
  // Calculate how far the user has dragged across the view
  CGPoint velocity = [recognizer velocityInView:self.view];
  CGFloat progress = [recognizer translationInView:self.view].x / self.view.width;

  progress = MIN(1, MAX(0, progress));

  if (recognizer.state == UIGestureRecognizerStateBegan) {
    // Create a interactive transition and pop the view controller
    self.interactivePopTransition = [UIPercentDrivenInteractiveTransition new];
    [self popViewControllerAnimated:YES];
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    // Update the interactive transition's progress
    [self.interactivePopTransition updateInteractiveTransition:progress];
  } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
    // Finish or cancel the interactive transition
    if (progress > 0.5f) {
      [self.interactivePopTransition finishInteractiveTransition];
    } else if (velocity.x > 0) {
      [self.interactivePopTransition finishInteractiveTransition];
    } else {
      [self.interactivePopTransition cancelInteractiveTransition];
    }

    self.interactivePopTransition = nil;
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  if ((gestureRecognizer == self.popGestureRecognizer || gestureRecognizer == self.interactivePopGestureRecognizer) && gestureRecognizer.state != UIGestureRecognizerStateFailed) {
    otherGestureRecognizer.enabled = NO;
    if (!self.disabledGestureRecognizers) {
      self.disabledGestureRecognizers = [NSMutableArray new];
    }
    [self.disabledGestureRecognizers addObject:otherGestureRecognizer];
  }

  return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  // Don't handle gestures if navigation controller is still animating a transition
  if ([self.transitionCoordinator isAnimated]) {
    return NO;
  }

  if (self.viewControllers.count < 2) {
    return NO;
  }

  id <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate> sourceTransition = (id<SEAZoomTransitionAnimating, SEAZoomTransitionDelegate>)self.viewControllers[self.viewControllers.count - 1];
  id <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate> destinationTransition = (id<SEAZoomTransitionAnimating, SEAZoomTransitionDelegate>)self.viewControllers[self.viewControllers.count - 2];

  BOOL shouldUseCustom = [sourceTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [destinationTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)];
  if (shouldUseCustom) {
    shouldUseCustom = [sourceTransition transitionSourceImageView] && !CGRectEqualToRect([destinationTransition transitionDestinationImageViewFrame], CGRectZero);
  }

  if (shouldUseCustom) {
    if (gestureRecognizer == self.popGestureRecognizer) {
      return YES;
    }
  } else if (gestureRecognizer == self.interactivePopGestureRecognizer) {
    return YES;
  }

  return NO;
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  for (UIGestureRecognizer *gestureRecognizer in self.disabledGestureRecognizers) {
    gestureRecognizer.enabled = YES;
  }

  self.disabledGestureRecognizers = [NSMutableArray new];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
  id <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate> sourceTransition = (id<SEAZoomTransitionAnimating, SEAZoomTransitionDelegate>)fromVC;
  id <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate> destinationTransition = (id<SEAZoomTransitionAnimating, SEAZoomTransitionDelegate>)toVC;
  BOOL shouldAnimate = [sourceTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)] && [destinationTransition conformsToProtocol:@protocol(SEAZoomTransitionAnimating)];
  if (shouldAnimate) {
    shouldAnimate = [sourceTransition transitionSourceImageView] && !CGRectEqualToRect([destinationTransition transitionDestinationImageViewFrame], CGRectZero);
  }

  if (shouldAnimate) {
    SEAZoomTransitionAnimator *animator = [SEAZoomTransitionAnimator new];
    animator.goingForward = (operation == UINavigationControllerOperationPush);
    animator.sourceTransition = sourceTransition;
    animator.destinationTransition = destinationTransition;
    return animator;
  } else if ([destinationTransition respondsToSelector:@selector(restoreLastSelectedPoster)]) {
    [destinationTransition performSelector:@selector(restoreLastSelectedPoster)];
  }

  return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
  return self.interactivePopTransition;
}

@end
