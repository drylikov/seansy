#import <AYSlidingPickerView/AYSlidingPickerView.h>

@interface SEAMainTabBarController : UITabBarController

#pragma mark Properties

@property (nonatomic) AYSlidingPickerView *locationPickerView;

#pragma mark Methods

+ (SEAMainTabBarController *)sharedInstance;
- (void)refreshNowPlayingMovies;
- (void)refreshTheatres;
- (void)refreshNews;
- (void)openMovieWithId:(NSInteger)movieId;

@end
