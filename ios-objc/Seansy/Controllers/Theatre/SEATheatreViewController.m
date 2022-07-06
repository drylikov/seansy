#import "SEATheatreViewController.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "SEAMainTabBarController.h"
#import "SEAMapViewController.h"
#import "SEAMoviesFilter.h"
#import "SEAMovieViewController.h"
#import "SEAShowtimesSectionHeaderView.h"
#import "SEAShowtimeViewController.h"
#import "SEATicketonViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <Doppelganger/Doppelganger.h>
#import <SDWebImage/UIImageView+WebCache.h>

static UIEdgeInsets const kTheatreViewTableHeaderPadding = {
  10, 10, 10, 10
};
static CGFloat const kTheatreViewTableHeaderVerticalSpacing = 10;
static CGFloat const kTheatreViewTableHeaderButtonsSpacing = 10;
static CGFloat const kTheatreViewTableHeaderButtonHeight = 40;
static CGFloat const kTheatreViewTableHeaderButtonIconMargin = 10;

@interface SEATheatreViewController () <UITableViewDataSource, UITableViewDelegate, SEAShowtimesSectionHeaderViewDelegate, UIScrollViewDelegate, SEAShowtimesCellDelegate>

@property (nonatomic) NSArray *movies;
@property (nonatomic) NSMutableArray *cells;
@property (nonatomic) NSString *city;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, getter = isAnimatingPopTip) BOOL animatingPopTip;
@property (weak, nonatomic) AMPopTip *visiblePopTip;
@property (weak, nonatomic) id<SEAPosterViewDelegate> lastSelectedPosterView;
@property (weak, nonatomic) SEATheatre *theatre;

@end

@implementation SEATheatreViewController

#pragma mark Initialization

- (instancetype)initWithTheatre:(SEATheatre *)theatre {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.theatre = theatre;

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.city = [[SEADataManager sharedInstance] citySupported] ? [SEALocationManager sharedInstance].currentCity : @"Не найдено";
  [[SEGAnalytics sharedAnalytics] screen:@"Cinema" properties:@{
     @"cinema" : self.theatre.name,
     @"city" : self.city
   }];

  self.automaticallyAdjustsScrollViewInsets = NO;
  self.edgesForExtendedLayout = UIRectEdgeBottom;
  self.view.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

  [self setUpNavigationBarButtons];
  [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self hideVisiblePopTip];
}

#pragma mark Public

- (void)restoreLastSelectedPoster {
  [self.lastSelectedPosterView restorePoster];
}

#pragma mark Getters

- (UITableView *)tableView {
  if (_tableView) {
    return _tableView;
  }

  _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _tableView.backgroundColor = [UIColor clearColor];
  _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  _tableView.allowsSelection = NO;
  [_tableView registerClass:[SEAShowtimesSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];
  [_tableView registerClass:[SEAShowtimesCarousel class] forCellReuseIdentifier:NSStringFromClass([SEAShowtimesCarousel class])];
  [self.view addSubview:_tableView];

  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
  [_tableView addGestureRecognizer:self.tapGestureRecognizer];

  return _tableView;
}

#pragma mark Private

- (void)refresh {
  [self hideVisiblePopTip];

  NSArray *oldMovies = self.movies;
  self.movies = [[SEADataManager sharedInstance] sortedMovies:[[SEADataManager sharedInstance] filteredMovies:[[SEADataManager sharedInstance] moviesForTheatre:self.theatre]]];
  if (self.view.window) {
    NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.movies previousArray:oldMovies];
    [self.tableView wml_applyBatchChangesForSections:diffs withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
      self.cells = [NSMutableArray new];
      [self.tableView reloadData];
    }];
  } else {
    self.cells = [NSMutableArray new];
    [self.tableView reloadData];
  }

  [self setUpTableHeader];
}

- (void)setUpTableHeader {
  UIToolbar *tableHeaderView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
  tableHeaderView.barStyle = UIBarStyleBlack;

  UIView *backgroundWrapper = [[UIView alloc] initWithFrame:tableHeaderView.bounds];
  [tableHeaderView addSubview:backgroundWrapper];

  NSMutableArray *locationComps = [NSMutableArray new];
  if (self.theatre.address) {
    [locationComps addObject:self.theatre.address];
  }
  if ([self.theatre formattedPhone]) {
    [locationComps addObject:[self.theatre formattedPhone]];
  }
  CGFloat verticalOffset = kTheatreViewTableHeaderPadding.top;
  if (locationComps.count > 0) {
    UILabel *theatreInfo = [[UILabel alloc] initWithFrame:CGRectMake(kTheatreViewTableHeaderPadding.left, verticalOffset, self.view.width - kTheatreViewTableHeaderPadding.left - kTheatreViewTableHeaderPadding.right, 0)];
    theatreInfo.text = [locationComps componentsJoinedByString:@"\n"];
    theatreInfo.textColor = [UIColor whiteColor];
    theatreInfo.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
    theatreInfo.numberOfLines = 0;
    [theatreInfo setFrameToFitWithHeightLimit:100];
    [tableHeaderView addSubview:theatreInfo];
    verticalOffset = theatreInfo.bottom + kTheatreViewTableHeaderVerticalSpacing;
  }

  NSMutableArray *buttons = [NSMutableArray new];
  CGFloat horizontalOffset = kTheatreViewTableHeaderPadding.left;
  if (self.theatre.phone) {
    UIButton *callButton = [[UIButton alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, (self.view.width - kTheatreViewTableHeaderPadding.left - kTheatreViewTableHeaderButtonsSpacing - kTheatreViewTableHeaderPadding.right) / 2, kTheatreViewTableHeaderButtonHeight)];
    horizontalOffset += callButton.width + kTheatreViewTableHeaderButtonsSpacing;
    [callButton setImage:[[UIImage imageNamed:@"PhoneIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [callButton addTarget:self action:@selector(call) forControlEvents:UIControlEventTouchUpInside];
    [callButton setTitle:NSLocalizedString(@"Позвонить", nil) forState:UIControlStateNormal];
    [buttons addObject:callButton];
    [tableHeaderView addSubview:callButton];
  }
  if (self.theatre.address) {
    UIButton *directionsButton = [[UIButton alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, (self.view.width - kTheatreViewTableHeaderPadding.left - kTheatreViewTableHeaderButtonsSpacing - kTheatreViewTableHeaderPadding.right) / 2, kTheatreViewTableHeaderButtonHeight)];
    if ([[self backViewController] class] == [SEAMapViewController class]) {
      [directionsButton setImage:[[UIImage imageNamed:@"DirectionsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
      [directionsButton addTarget:self action:@selector(openDirections) forControlEvents:UIControlEventTouchUpInside];
      [directionsButton setTitle:NSLocalizedString(@"Навигация", nil) forState:UIControlStateNormal];
    } else {
      [directionsButton setImage:[[UIImage imageNamed:@"MapIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
      [directionsButton addTarget:self action:@selector(openMaps) forControlEvents:UIControlEventTouchUpInside];
      [directionsButton setTitle:NSLocalizedString(@"На карте", nil) forState:UIControlStateNormal];
    }
    [buttons addObject:directionsButton];
    [tableHeaderView addSubview:directionsButton];
  }

  for (UIButton *button in buttons) {
    button.tintColor = [UIColor colorWithHexString:kOnyxColor];
    [button setTitleColor:[UIColor colorWithHexString:kOnyxColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, kTheatreViewTableHeaderButtonIconMargin);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, kTheatreViewTableHeaderButtonIconMargin, 0, 0);
    button.layer.backgroundColor = [UIColor colorWithHexString:kAmberColor].CGColor;
    button.layer.cornerRadius = button.height / 2;
  }

  if (buttons.count > 0) {
    verticalOffset += kTheatreViewTableHeaderButtonHeight + kTheatreViewTableHeaderVerticalSpacing;
  }
  backgroundWrapper.height = verticalOffset;
  UIImageView *background = [[UIImageView alloc] initWithFrame:backgroundWrapper.bounds];
  [self.theatre.backdrop getOriginalImageWithProgressBlock:nil completionBlock:^(UIImage *originalImage, BOOL fromCache) {
    if (originalImage) {
      background.image = originalImage;
    }
  }];
  background.contentMode = UIViewContentModeScaleAspectFill;
  CAGradientLayer *gradient = [CAGradientLayer layer];
  gradient.frame = backgroundWrapper.frame;
  CGColorRef topColor = [UIColor colorWithWhite:0 alpha:0.25f].CGColor;
  CGColorRef bottomColor = [UIColor colorWithWhite:0 alpha:0].CGColor;
  gradient.startPoint = CGPointMake(0.5f, 0);
  gradient.endPoint = CGPointMake(0.5f, 1);
  gradient.colors = @[(__bridge id)topColor, (__bridge id)topColor,  (__bridge id)bottomColor];
  backgroundWrapper.layer.mask = gradient;
  [backgroundWrapper addSubview:background];

  UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, verticalOffset, self.view.width, 1 / UIScreen.mainScreen.scale)];
  verticalOffset = separator.bottom + kTheatreViewTableHeaderVerticalSpacing;
  separator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];
  [tableHeaderView addSubview:separator];

  UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(kTheatreViewTableHeaderPadding.left, verticalOffset, self.view.width - kTheatreViewTableHeaderPadding.left - kTheatreViewTableHeaderPadding.right, 0)];
  if (self.movies.count > 0) {
    title.text = [NSString localizedStringWithFormat:@"Расписание кинотеатра на %@", [SEADataManager sharedInstance].selectedDayIndex == SEAShowtimesDateToday ? NSLocalizedString(@"cегодня", nil) : NSLocalizedString(@"завтра", nil)];
  } else {
    title.text = NSLocalizedString(@"Расписания пока нет, попробуйте зайти позже.", nil);
  }
  title.textColor = [UIColor whiteColor];
  title.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  title.textAlignment = NSTextAlignmentCenter;
  title.numberOfLines = 2;
  [title setFrameToFitWithHeightLimit:60];
  [tableHeaderView addSubview:title];
  verticalOffset = title.bottom;
  if (self.movies.count > 0) {
    verticalOffset += kTheatreViewTableHeaderVerticalSpacing / 2;
  } else {
    verticalOffset += kTheatreViewTableHeaderVerticalSpacing;
  }

  if (self.movies.count > 0) {
    UILabel *notice = [[UILabel alloc] initWithFrame:CGRectMake(kTheatreViewTableHeaderPadding.left, verticalOffset, self.view.width - kTheatreViewTableHeaderPadding.left - kTheatreViewTableHeaderPadding.right, 0)];
    notice.text = NSLocalizedString(@"(Возможны изменения)", nil);
    notice.textColor = [UIColor colorWithWhite:1 alpha:kSecondaryTextAlpha];
    notice.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
    notice.textAlignment = NSTextAlignmentCenter;
    notice.numberOfLines = 0;
    [notice setFrameToFitWithHeightLimit:60];
    [tableHeaderView addSubview:notice];
    verticalOffset = notice.bottom + kTheatreViewTableHeaderPadding.bottom;
  }

  tableHeaderView.height = verticalOffset;
  self.tableView.tableHeaderView = tableHeaderView;
}

- (void)openMaps {
  [[SEAMapViewController sharedInstance] setSelectedTheatre:self.theatre];
  [[SEGAnalytics sharedAnalytics] track:@"Opened the map" properties:@{
     @"from" : @"cinema",
     @"cinema" : self.theatre.name,
     @"city" : self.city
   }];
  [self.navigationController pushViewController:[SEAMapViewController sharedInstance] animated:YES];
}

- (void)openDirections {
  [[SEGAnalytics sharedAnalytics] track:@"Opened directions" properties:@{
     @"cinema" : self.theatre.name,
     @"city" : self.city
   }];
  [self.theatre openDirections];
}

- (void)call {
  [[SEGAnalytics sharedAnalytics] track:@"Called cinema" properties:@{
     @"cinema" : self.theatre.name,
     @"city" : self.city
   }];
  [self.theatre call];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
  CGPoint tapLocation = [tapGestureRecognizer locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];

  if (indexPath) {
    tapGestureRecognizer.cancelsTouchesInView = NO;
  } else {
    [self hideVisiblePopTip];
  }
}

- (void)setUpNavigationBarButtons {
  UIButton *sortButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];

  [sortButton setBackgroundImage:[[UIImage imageNamed:@"SortIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [sortButton addTarget:self action:@selector(openSortView) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *sortButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sortButton];

  UIButton *filterButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [filterButton setBackgroundImage:[[UIImage imageNamed:@"FilterIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [filterButton addTarget:self action:@selector(openFilterView) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *filterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filterButton];

  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
  space.width = 15;

  self.navigationItem.rightBarButtonItems = @[filterButtonItem, space, sortButtonItem];
}

- (void)openSortView {
  SEAActionSheet *actionSheet = [[SEAActionSheet alloc] initWithTitle:NSLocalizedString(@"Сортировать фильмы", nil)];
  actionSheet.activeIndex = (NSUInteger)[[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kMoviesSortByKey];

  void (^buttonClicked)(SEAMoviesSortBy) = ^(SEAMoviesSortBy sortBy) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setInteger:sortBy forKey:kMoviesSortByKey];
    [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
    [self refresh];
  };
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По названию", nil) image:[UIImage imageNamed:@"SortByName"] handler:^{
    buttonClicked(SEAMoviesSortByName);
  }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По популярности", nil) image:[UIImage imageNamed:@"SortByPopularity"] handler:^{
    buttonClicked(SEAMoviesSortByPopularity);
  }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По рейтингу", nil) image:[UIImage imageNamed:@"SortByRating"] handler:^{
    buttonClicked(SEAMoviesSortByRating);
  }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По количеству сеансов", nil) image:[UIImage imageNamed:@"SortByShowtimesCount"] handler:^{
    buttonClicked(SEAMoviesSortByShowtimesCount);
  }];

  [self showActionSheet:actionSheet];
}

- (void)openFilterView {
  SEAActionSheet *actionSheet = [[SEAActionSheet alloc] initWithTitle:NSLocalizedString(@"Фильтровать фильмы", nil)];

  actionSheet.cancelButtonTitle = NSLocalizedString(@"Готово", nil);
  actionSheet.dismissHandler = ^{
    [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
    [self refresh];
  };
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] ratingSlider]];
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] runtimeSlider]];
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] childrenSwitch]];
  [actionSheet addView:[[SEAMoviesFilter sharedInstance] genresSelector]];

  [self showActionSheet:actionSheet];
}

- (void)showActionSheet:(SEAActionSheet *)actionSheet {
  if (self.visiblePopTip) {
    __weak typeof(self) weakSelf = self;
    void (^oldDismissHandler)() = self.visiblePopTip.dismissHandler;
    self.visiblePopTip.dismissHandler = ^{
      oldDismissHandler();
      weakSelf.visiblePopTip = nil;
      [actionSheet show];
    };
    [self.visiblePopTip hide];
  } else {
    [actionSheet show];
  }
}

#pragma mark Setters

- (void)setTheatre:(SEATheatre *)theatre {
  _theatre = theatre;
  self.navigationItem.title = self.theatre.name;
}

#pragma mark Helpers

- (UIViewController *)backViewController {
  NSUInteger numberOfViewControllers = self.navigationController.viewControllers.count;

  if (numberOfViewControllers < 2) {
    return nil;
  } else {
    return self.navigationController.viewControllers[numberOfViewControllers - 2];
  }
}

- (void)hideVisiblePopTip {
  if (self.visiblePopTip && !self.isAnimatingPopTip) {
    self.animatingPopTip = YES;
    void (^oldDismissHandler)() = self.visiblePopTip.dismissHandler;
    self.visiblePopTip.dismissHandler = ^{
      oldDismissHandler();
      self.animatingPopTip = NO;
    };
    [self.visiblePopTip hide];
  }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.movies.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return kMovieSectionHeaderViewHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kShowtimesCarouselHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  SEAShowtimesSectionHeaderView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];
  headerView.delegate = self;
  headerView.movie = self.movies[(NSUInteger)section];
  [headerView setUpArrowIconWithOrientation:SEAArrowIconOrientationVertical];
  return headerView;
}

- (void)sectionHeaderViewBackdropTapped:(SEAShowtimesSectionHeaderView *)headerView {
  if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
    self.lastSelectedPosterView = headerView;
    SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:headerView.movie];
    [self.navigationController pushViewController:movieViewController animated:YES];
  }
}

- (void)sectionHeaderViewPosterTapped:(SEAShowtimesSectionHeaderView *)headerView {
  if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
    self.lastSelectedPosterView = headerView;
    SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:headerView.movie];
    [self.navigationController pushViewController:movieViewController animated:YES];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SEAShowtimesCarousel *cell = (SEAShowtimesCarousel *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEAShowtimesCarousel class]) forIndexPath:indexPath];

  cell.containerView = self.tableView;
  cell.currentLayout = SEAShowtimesLayoutMovies;
  cell.popTipDelegate = self;
  cell.theatre = self.theatre;
  cell.movie = self.movies[(NSUInteger)indexPath.section];
  [self.cells addObject:cell];
  return cell;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [self hideVisiblePopTip];
}

#pragma mark SEAShowtimesCarouselDelegate

- (SEAShowtimesItemCell *)cellForVisiblePopTip {
  for (SEAShowtimesCarousel *carousel in self.cells) {
    if ([carousel hasPoptip:self.visiblePopTip]) {
      return carousel.activeCell;
    }
  }
  return nil;
}

- (void)openShowtime:(SEAShowtime *)showtime {
  SEAShowtimeViewController *showtimeViewController = [[SEAShowtimeViewController alloc] initWithShowtime:showtime];
  [self presentViewController:showtimeViewController animated:YES completion:nil];
}

- (void)buyTicketForShowtime:(SEAShowtime *)showtime {
  SEATicketonViewController *ticketonViewController = [[SEATicketonViewController alloc] initWithShowtime:showtime];
  [self presentViewController:ticketonViewController animated:YES completion:nil];
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
