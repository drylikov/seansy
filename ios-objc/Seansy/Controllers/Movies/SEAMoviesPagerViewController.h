#import "SEAPagerViewController.h"

@interface SEAMoviesPagerViewController : SEAPagerViewController

- (RACSignal *)refreshNowPlayingMovies;
- (RACSignal *)refreshComingSoonMovies;
- (void)openMovieWithId:(NSInteger)movieId;

@end
