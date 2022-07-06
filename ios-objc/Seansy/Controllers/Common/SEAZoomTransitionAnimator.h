@class SEAZoomTransitionAnimator;

/**
 * You need to adopt the RMPZoomTransitionAnimating protocol in source view controller and destination
 * view controller to make transition animations.
 *
 * The animator get the image position from a view controller implemented this protocol.
 */
@protocol SEAZoomTransitionAnimating <NSObject>
@required
/**
 * Before the animation occurs, return the UIImageView of transition source view controller.
 *
 * You should create a new UIImageView object again, so this UIImageView is moving.
 *
 * @return source view controller's UIImageView before transition.
 */
- (UIImageView *)transitionSourceImageView;
/**
 * Returns the UIImageView’s rectangle in a destination view controller.
 *
 * @return destination view controller's frame for UIImageView
 */
- (CGRect)transitionDestinationImageViewFrame;
@end

/**
 * Delegate handler of viewController which implements transitioning protocol
 */
@protocol SEAZoomTransitionDelegate <NSObject>
@optional
/**
 * Notify the end of the forward and backward animations.
 *
 * get the original UIImageView and hide it, while the copy is being animated.
 * And when the animation is done, the original could be shown.
 * That will prevent the original views to be shown while animating.
 */
- (void)zoomTransitionAnimator:(SEAZoomTransitionAnimator *)animator didCompleteTransition:(BOOL)didComplete animatingSourceImageView:(UIImageView *)imageView;
/**
 * Notify the start of the forward and backward animations.
 */
- (void)zoomTransitionAnimatorWillStartTransition:(SEAZoomTransitionAnimator *)animator;
@end

/**
 * Animator object that implements UIViewControllerAnimatedTransitioning
 *
 * You need to return this object in transition delegate method
 */
@interface SEAZoomTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

/**
 * A Boolean value that determines whether transition animation is going forward.
 */
@property (nonatomic) BOOL goingForward;
/**
 * The animator's delegate for transition in source view controller.
 *
 * You need to set this property and implement the RMPZoomTransitionAnimating in source view controller.
 */
@property (nonatomic, weak) id <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate> sourceTransition;
/**
 * The animator's delegate for transition in destination view controller.
 *
 * You need to set this property and implement the RMPZoomTransitionAnimating in destination view controller.
 */
@property (nonatomic, weak) id <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate> destinationTransition;

@end
