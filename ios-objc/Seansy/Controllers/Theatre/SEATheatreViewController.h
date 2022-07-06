#import "SEAShowtimesCarousel.h"
#import "SEATheatre.h"
#import "SEAZoomTransitionAnimator.h"
#import <AMPopTip/AMPopTip.h>

@interface SEATheatreViewController : UIViewController <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate>

- (instancetype)initWithTheatre:(SEATheatre *)theatre;
- (void)restoreLastSelectedPoster;

@end
