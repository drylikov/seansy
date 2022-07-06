#import "SEAOnboardingViewController.h"

@interface SEAWalkthroughViewController : SEAOnboardingViewController

/**
 *  Create a walkthrough view with an action that will execute after the exit button is tapped.
 *
 *  @param completionHandler Block which gets called when the skip button is tapped.
 *
 *  @return Newly created walthrought view controller.
 */
- (instancetype)initWithCompletionHandler:(dispatch_block_t)completionHandler;
/**
 *  Create a walkthrough view with an action that will execute after the exit button is tapped.
 *
 *  @param completionHandler Block which gets called when the skip button is tapped.
 *  @param replay            Whether or not is is a replay, which means that all pages will be showed.
 *
 *  @return Newly created walthrought view controller.
 */
- (instancetype)initWithCompletionHandler:(dispatch_block_t)completionHandler replay:(BOOL)replay;
+ (BOOL)hasUnseenNewFeatures;

@end
