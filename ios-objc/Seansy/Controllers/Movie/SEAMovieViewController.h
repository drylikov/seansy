#import "SEAMovie.h"
#import "SEAZoomTransitionAnimator.h"

@interface SEAMovieViewController : UIViewController <SEAZoomTransitionAnimating, SEAZoomTransitionDelegate>

- (instancetype)initWithMovie:(SEAMovie *)movie;
- (void)refresh;

@end
