//
//  Copyright (c) 2014 Callum Boddy, 2015 Ayan Yenbekbay.
//

/**
 *  The abstract class that provides the common interface between all splash view implementations.
 */
@interface SEASplashView : UIView

/**
 *  This initializer takes a raster image that will be used in the animation.
 *
 *  The animation is first scales the image down a bit, then, simultanuously scales it all the way up and
 *  fades the view out.
 *
 *  @param icon            The icon image in the centre
 *  @param backgroundColor The background color of the entire view
 *  @param iconColor       The color for the image icon
 *  @param iconSize        The starting size of the centred icon
 *
 *  @return The Splash view
 */
- (instancetype)initWithIconImage:(UIImage *)icon backgroundColor:(UIColor *)backgroundColor iconColor:(UIColor *)iconColor iconSize:(CGSize)iconSize;
/**
 *  Call to start the animation.
 */
- (void)startAnimation;
/**
 *  Call to start the animation with completion handler.
 */
- (void)startAnimationWithCompletionHandler:(void (^)())completionHandler;

#pragma mark Properties

/**
 *  The starting size of the centred icon.
 */
@property (nonatomic, assign) CGSize iconStartSize;
/**
 *  Total length of animation.
 */
@property (nonatomic) CGFloat animationDuration;
/**
 *  The animation applied to the icon
 */
@property (nonatomic) CAAnimation *iconAnimation;

@end
