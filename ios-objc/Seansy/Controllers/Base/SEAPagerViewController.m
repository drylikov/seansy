#import "SEAPagerViewController.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAMainTabBarController.h"
#import "SEAMoviesFilter.h"
#import "UIView+AYUtils.h"

@interface SEAPagerViewController ()

@property (nonatomic) CGFloat percentHidden;
@property (nonatomic, getter = isAnimatingBars) BOOL animatingBars;
@property (nonatomic, getter = isVisible) BOOL visible;
@property (nonatomic, getter = shouldHideTabBar) BOOL hideTabBar;
@property (nonatomic) UIBarButtonItem *sortButtonItem;
@property (nonatomic) UIBarButtonItem *filterButtonItem;

@end

@implementation SEAPagerViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.automaticallyAdjustsScrollViewInsets = NO;
  [self.view addSubview:self.buttonBarView];
  [self setUpNavigationBarButtons];
  self.ready = _ready;
  self.isProgressiveIndicator = YES;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = nil;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.visible = YES;
  [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0 options:0 animations:^{
    self.tabBarController.tabBar.top = self.navigationController.view.bottom - self.tabBarController.tabBar.height * (1 - self.percentHidden);
  } completion:nil];
  [[AYSlidingPickerView sharedInstance] addGestureRecognizersToNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self restoreBarsAnimated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  self.visible = NO;
  self.hideTabBar = NO;
  [[AYSlidingPickerView sharedInstance] removeGestureRecognizersFromNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  [self updateBars];
}

#pragma mark SEAPageItemViewControllerDelegate

- (void)setPercentHidden:(CGFloat)percentHidden interactive:(BOOL)interactive {
  percentHidden = MAX(0, MIN(1, percentHidden));
  if (percentHidden == self.percentHidden) {
    return;
  }
  self.percentHidden = percentHidden;
  [self updateBarsAnimated:!interactive];
}

- (CGFloat)topHeight {
  return self.navigationController.navigationBar.height;
}

- (CGFloat)bottomHeight {
  return self.tabBarController.tabBar.height;
}

- (CGFloat)buttonBarHeight {
  return self.buttonBarView.height;
}

#pragma mark Setters

- (void)setReady:(BOOL)ready {
  _ready = ready;
  self.sortButtonItem.enabled = self.filterButtonItem.enabled = ready;
}

#pragma mark Public

- (RACSignal *)refresh {
  return [RACSignal empty];
}

- (void)restoreBars {
  [self restoreBarsAnimated:NO];
}

- (UICollectionView *)activeScrollView {
  return nil;
}

- (void)showActionSheet:(SEAActionSheet *)actionSheet {
  [actionSheet show];
}

- (void)restoreLastSelectedPoster {
  [self.lastSelectedPosterView restorePoster];
}

- (id<SEAPosterViewDelegate>)lastSelectedPosterView {
  return nil;
}

#pragma mark Private

- (void)setUpNavigationBarButtons {
  UIButton *sortButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];

  [sortButton setBackgroundImage:[[UIImage imageNamed:@"SortIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [sortButton addTarget:self action:@selector(openSortView) forControlEvents:UIControlEventTouchUpInside];
  self.sortButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sortButton];

  UIButton *filterButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [filterButton setBackgroundImage:[[UIImage imageNamed:@"FilterIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [filterButton addTarget:self action:@selector(openFilterView) forControlEvents:UIControlEventTouchUpInside];
  self.filterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filterButton];

  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
  space.width = 15;

  self.navigationItem.leftBarButtonItems = @[self.sortButtonItem, space, self.filterButtonItem];
}

- (void)restoreBarsAnimated:(BOOL)animated {
  if (self.visible) {
    self.percentHidden = 0;
    [self updateBarsAnimated:animated];
  }
}

- (void)updateBarsAnimated:(BOOL)animated {
  if (animated) {
    self.animatingBars = YES;
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0 options:0 animations:^{
      [self updateBars];
    } completion:^(BOOL finished) {
      self.animatingBars = NO;
    }];
  } else {
    [self updateBars];
  }
}

- (void)updateBars {
  CGFloat toBottom = self.activeScrollView.contentSize.height - self.activeScrollView.height - self.activeScrollView.contentOffset.y - self.activeScrollView.contentInset.top;

  if (self.navigationController.navigationBar.top < 0 && self.percentHidden == 0 && toBottom <= 0) {
    self.activeScrollView.contentOffset = CGPointMake(0, self.activeScrollView.contentOffset.y + self.navigationController.navigationBar.height);
  }

  if (self.tabBarController.tabBar.top == self.navigationController.view.bottom && self.percentHidden == 0 && toBottom <= 0) {
    self.activeScrollView.contentOffset = CGPointMake(0, self.activeScrollView.contentOffset.y + self.tabBarController.tabBar.height);
  }

  self.navigationController.navigationBar.top = -self.navigationController.navigationBar.height * self.percentHidden;
  if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
    self.buttonBarView.top = MAX(self.navigationController.navigationBar.bottom, 0);
    self.activeScrollView.contentInset = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height * (1 - self.percentHidden), 0);
    self.activeScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height * (1 - self.percentHidden), 0);
  } else {
    self.navigationController.navigationBar.top += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) * (1 - self.percentHidden);
    self.buttonBarView.top = MAX(self.navigationController.navigationBar.bottom, 0) + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) * self.percentHidden;
    self.activeScrollView.contentInset = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height, 0);
    self.activeScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height, 0);
  }

  self.containerView.top = self.buttonBarView.bottom;
  self.containerView.height = self.view.height - self.buttonBarView.bottom;
  if (self.percentHidden == 1) {
    self.navigationController.navigationBar.top -= 1;
  }

  if (self.shouldHideTabBar) {
    self.tabBarController.tabBar.top = self.navigationController.view.bottom;
  } else if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
    self.tabBarController.tabBar.top = self.navigationController.view.bottom - self.tabBarController.tabBar.height * (1 - self.percentHidden);
  } else {
    self.tabBarController.tabBar.top = self.navigationController.view.bottom - self.tabBarController.tabBar.height;
  }
}

- (void)openSortView {
  SEAActionSheet *actionSheet = [[SEAActionSheet alloc] initWithTitle:NSLocalizedString(@"Сортировать фильмы", nil)];
  actionSheet.activeIndex = (NSUInteger)[[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kMoviesSortByKey];

  void (^buttonClicked)(SEAMoviesSortBy) = ^(SEAMoviesSortBy sortBy) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setInteger:sortBy forKey:kMoviesSortByKey];
    [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
  };
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По названию", nil) image:[UIImage imageNamed:@"SortByName"] handler:^{ buttonClicked(SEAMoviesSortByName); }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По популярности", nil) image:[UIImage imageNamed:@"SortByPopularity"] handler:^{ buttonClicked(SEAMoviesSortByPopularity); }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По рейтингу", nil) image:[UIImage imageNamed:@"SortByRating"] handler:^{ buttonClicked(SEAMoviesSortByRating); }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По количеству сеансов", nil) image:[UIImage imageNamed:@"SortByShowtimesCount"] handler:^{ buttonClicked(SEAMoviesSortByShowtimesCount); }];
  [self showActionSheet:actionSheet];
}

- (void)openFilterView {
  if ([[SEADataManager sharedInstance] localNowPlayingMovies].count == 0) {
    return;
  }

  SEAActionSheet *actionSheet = [[SEAActionSheet alloc] initWithTitle:NSLocalizedString(@"Фильтровать фильмы", nil)];
  actionSheet.cancelButtonTitle = NSLocalizedString(@"Готово", nil);
  actionSheet.dismissHandler = ^{
    [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
  };
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] ratingSlider]];
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] runtimeSlider]];
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] childrenSwitch]];
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] genresSelector]];

  [self showActionSheet:actionSheet];
}

#pragma mark RMPZoomTransitionAnimating

- (UIImageView *)transitionSourceImageView {
  UIImageView *originalPoster = self.lastSelectedPosterView.poster;
  if (!originalPoster) {
    return nil;
  }
  UIImageView *transitionPoster = [[UIImageView alloc] initWithImage:originalPoster.image];
  transitionPoster.contentMode = UIViewContentModeScaleToFill;
  transitionPoster.clipsToBounds = YES;
  transitionPoster.frame = [originalPoster convertRect:originalPoster.frame toView:self.navigationController.view];
  return transitionPoster;
}

- (CGRect)transitionDestinationImageViewFrame {
  UIImageView *originalPoster = self.lastSelectedPosterView.poster;
  if (!originalPoster) {
    return CGRectZero;
  }
  return [originalPoster convertRect:originalPoster.frame toView:self.navigationController.view];
}

#pragma mark RMPZoomTransitionDelegate

- (void)zoomTransitionAnimatorWillStartTransition:(SEAZoomTransitionAnimator *)animator {
  self.lastSelectedPosterView.poster.alpha = 0;
}

- (void)zoomTransitionAnimator:(SEAZoomTransitionAnimator *)animator didCompleteTransition:(BOOL)didComplete animatingSourceImageView:(UIImageView *)imageView {
  self.lastSelectedPosterView.poster.alpha = 1;
}

@end
