#import "SEAMovieViewController.h"

#import "SEAAlertView.h"
#import "SEAAppDelegate.h"
#import "SEAConstants.h"
#import "SEAGlassScrollView.h"
#import "SEAMainTabBarController.h"
#import "SEAMovieDetailsInfoView.h"
#import "SEAMovieShowtimesView.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <XCDYouTubeKit/XCDYouTubeVideoPlayerViewController.h>

@interface SEAMovieViewController () <SEAGlassScrollViewDelegate, SEAMovieDetailsInfoViewDelegate, SEAMovieShowtimesViewDelegate>

@property (nonatomic) SEAGlassScrollView *glassScrollView;
@property (nonatomic) SEAMovieDetailsInfoView *infoView;
@property (nonatomic) SEAMovieShowtimesView *showtimesView;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) XCDYouTubeVideoPlayerViewController *videoPlayerViewController;
@property (weak, nonatomic) SEAMovie *movie;
@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic, getter = isTrailerPlaying) BOOL trailerPlaying;

@end

@implementation SEAMovieViewController

#pragma mark Initialization

- (instancetype)initWithMovie:(SEAMovie *)movie {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.movie = movie;
  self.view.backgroundColor = [UIColor blackColor];
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.navigationItem.title = self.movie.title;
  [self refresh];

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[SEGAnalytics sharedAnalytics] screen:@"Movie" properties:@{ @"movie" : self.movie.title }];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [UIImage new];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  if (!self.infoView.delegate) {
    self.infoView.delegate = self;
  }
  if (!self.showtimesView.delegate) {
    self.showtimesView.delegate = self;
  }
  if (!self.glassScrollView.delegate) {
    self.glassScrollView.delegate = self;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (!self.glassScrollView.movie) {
    self.glassScrollView.movie = self.movie;
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.showtimesView hideVisiblePopTip];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Public

- (void)refresh {
  self.infoView = [[SEAMovieDetailsInfoView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0) movie:self.movie];
  self.showtimesView = [[SEAMovieShowtimesView alloc] initWithFrame:self.view.bounds movie:self.movie];
  if (self.glassScrollView) {
    [self.glassScrollView removeFromSuperview];
  }
  if (self.activityIndicatorView) {
    [self.activityIndicatorView removeFromSuperview];
    self.activityIndicatorView = nil;
  }
  self.glassScrollView = [[SEAGlassScrollView alloc] initWithFrame:self.view.bounds infoView:self.infoView showtimesView:self.showtimesView];
  [self.view addSubview:self.glassScrollView];
  [self.movie.backdrop getColorsWithCompletionBlock:^(NSDictionary *colors) {
    [self.infoView updateLabelColors:colors];
  }];
  if (self.view.window) {
    self.glassScrollView.movie = self.movie;
  } else {
    [self.glassScrollView setUpBackdropProgressView];
  }
  if (self.navigationController) {
    self.infoView.delegate = self;
    self.showtimesView.delegate = self;
    self.glassScrollView.delegate = self;
  }
}

#pragma mark Private

- (void)orientationChanged {
  if (!self.refreshTimer && [self isInLandscape] && !self.isTrailerPlaying) {
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(checkOrientation) userInfo:nil repeats:YES];
  }
}

- (void)checkOrientation {
  if (![self isInLandscape] && self.view.window) {
    [self refresh];
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
  }
}

#pragma mark Helpers

- (void)hideStatusBar {
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (BOOL)isInLandscape {
  return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
}

- (void)forceLandscapeOrientation {
  if (![self isInLandscape]) {
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
  }
}

- (void)forcePortraitOrientation {
  if ([self isInLandscape]) {
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
  }
}

- (void)restoreOrientation {
  [(SEAAppDelegate *)[UIApplication sharedApplication].delegate restoreOrientation];
}

- (void)blockOrientation {
  [(SEAAppDelegate *)[UIApplication sharedApplication].delegate setOrientationMask:UIInterfaceOrientationMaskPortrait];
}

- (CGFloat)topHeight {
  CGFloat topHeight = self.navigationController.navigationBar.height;

  if (![self isInLandscape]) {
    topHeight += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
  }
  return topHeight;
}

#pragma mark SEAGlassScrollViewDelegate & SEAMovieDetailsInfoViewDelegate

- (void)playTrailerForMovie:(SEAMovie *)movie {
  self.videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:movie.trailerId];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.videoPlayerViewController.moviePlayer];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.videoPlayerViewController.moviePlayer];
  [self restoreOrientation];
  self.trailerPlaying = YES;
  [self presentMoviePlayerViewControllerAnimated:self.videoPlayerViewController];
  [[SEGAnalytics sharedAnalytics] track:@"Watched trailer" properties:@{
     @"movie" : self.movie.title
   }];
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
  switch (self.videoPlayerViewController.moviePlayer.playbackState) {
    case MPMoviePlaybackStatePlaying:
      [self forceLandscapeOrientation];
    default:
      break;
  }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:notification.object];
  self.trailerPlaying = NO;
  if ([self isInLandscape]) {
    [self.glassScrollView removeFromSuperview];
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicatorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.activityIndicatorView startAnimating];
    [[UIApplication sharedApplication].delegate.window addSubview:self.activityIndicatorView];
    [self forcePortraitOrientation];
  }

  MPMovieFinishReason finishReason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
  if (finishReason == MPMovieFinishReasonPlaybackError) {
    NSString *title = NSLocalizedString(@"Ошибка", nil);
    NSError *error = notification.userInfo[XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey];
    NSString *body = [NSString stringWithFormat:@"%@", error.localizedDescription];
    SEAAlertView *alert = [[SEAAlertView alloc] initWithTitle:title body:body];
    [alert performSelector:@selector(show) withObject:nil afterDelay:1.5f];
  }
  [self blockOrientation];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent {
  [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

#pragma mark RMPZoomTransitionAnimating

- (UIImageView *)transitionSourceImageView {
  UIImageView *originalPoster = self.infoView.poster;
  if (!originalPoster || self.glassScrollView.currentPageIndex == 1) {
    return nil;
  }
  UIImageView *transitionPoster = [[UIImageView alloc] initWithImage:originalPoster.image];
  transitionPoster.contentMode = UIViewContentModeScaleToFill;
  transitionPoster.clipsToBounds = YES;
  transitionPoster.frame = [originalPoster convertRect:originalPoster.frame toView:self.view];
  transitionPoster.left = originalPoster.left;
  return transitionPoster;
}

- (CGRect)transitionDestinationImageViewFrame {
  UIImageView *originalPoster = self.infoView.poster;
  if (!originalPoster || self.glassScrollView.currentPageIndex == 1) {
    return CGRectZero;
  }
  CGRect transitionPosterFrame = [originalPoster convertRect:originalPoster.frame toView:self.view];
  transitionPosterFrame.origin.x = originalPoster.left;
  return transitionPosterFrame;
}

#pragma mark RMPZoomTransitionDelegate

- (void)zoomTransitionAnimatorWillStartTransition:(SEAZoomTransitionAnimator *)animator {
  self.infoView.poster.alpha = 0;
}

- (void)zoomTransitionAnimator:(SEAZoomTransitionAnimator *)animator didCompleteTransition:(BOOL)didComplete animatingSourceImageView:(UIImageView *)imageView {
  self.infoView.poster.alpha = 1;
  self.infoView.poster.image = imageView.image;
}

@end
