#import "SEAShowtimesPagerChildItemViewController.h"

#import "SEADataManager.h"
#import "SEAErrorView.h"
#import "SEALocationManager.h"
#import "SEAMovieViewController.h"
#import "SEAPickerView.h"
#import "SEAShowtimeViewController.h"
#import "SEATheatreViewController.h"
#import "SEATicketonViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Doppelganger/Doppelganger.h>

@interface SEAShowtimesPagerChildItemViewController () <SEAPickerViewDataSource, SEAPickerViewDelegate>

@property (nonatomic) NSArray *currentDateMovies;
@property (nonatomic) NSArray *movies;
@property (nonatomic) NSArray *showtimes;
@property (nonatomic) NSArray *dates;
@property (nonatomic) NSInteger currentActiveSection;
@property (nonatomic) NSInteger previousActiveSection;
@property (nonatomic) NSMutableArray *cells;
@property (nonatomic) NSString *city;
@property (nonatomic) NSDate *selectedDate;
@property (nonatomic) NSDate *currentDate;
@property (nonatomic) SEAErrorView *errorView;
@property (nonatomic) SEAPickerView *pickerView;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, getter = isAnimatingPopTip) BOOL animatingPopTip;
@property (weak, nonatomic) SEAShowtimesSectionHeaderView *currentActiveSectionHeaderView;
@property (weak, nonatomic) SEAShowtimesSectionHeaderView *previousActiveSectionHeaderView;
@property (nonatomic) RACSignal *refreshSignal;

@end

@implementation SEAShowtimesPagerChildItemViewController

#pragma mark Initialization

- (instancetype)initWithLayout:(SEAShowtimesLayout)layout {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.layout = layout;
  self.previousActiveSection = -1;
  self.currentActiveSection = -1;
  if (self.layout == SEAShowtimesLayoutTime) {
    [self setUpPickerView];
  }
  [self setUpTableView];
  [self setUpErrorView];

  return self;
}

#pragma mark Lifecycle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (self.layout == SEAShowtimesLayoutTime) {
    [self updatePickerView];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self hideVisiblePopTip];
}

#pragma mark Public

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

- (RACSignal *)refresh {
  if (self.refreshSignal) {
    return self.refreshSignal;
  }
  self.refreshSignal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    self.previousActiveSection = self.currentActiveSection;
    [self collapsePreviousActiveSectionWithCompletion:^{
      self.cells = [NSMutableArray new];
      if ([[SEADataManager sharedInstance] citySupported]) {
        self.city = [SEALocationManager sharedInstance].currentCity;
        self.selectedDate = [SEADataManager sharedInstance].selectedDate;
        NSArray *oldMovies = self.movies;
        self.movies = [[[SEADataManager sharedInstance] filteredMovies:[[SEADataManager sharedInstance] localNowPlayingMovies]] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary *bindings) {
          return [[SEADataManager sharedInstance] localShowtimesForMovie:(SEAMovie *)evaluatedObject].count > 0;
        }]];
        self.showtimes = [[SEADataManager sharedInstance] localShowtimesForMovies:self.movies];
        NSArray *oldDateMovies = self.currentDateMovies;
        self.currentDateMovies = [[SEADataManager sharedInstance] sortedMovies:[[SEADataManager sharedInstance] moviesForShowtimes:[SEADataManager filterShowtimes:self.showtimes date:self.currentDate]]];
        if (self.isViewLoaded && self.view.window) {
          if (self.layout == SEAShowtimesLayoutMovies) {
            NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.movies previousArray:oldMovies];
            [self.tableView wml_applyBatchChangesForSections:diffs withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
              [subscriber sendCompleted];
            }];
          } else {
            NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.currentDateMovies previousArray:oldDateMovies];
            [self.tableView wml_applyBatchChangesForRows:diffs inSection:0 withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
              [self.tableView reloadData];
              [subscriber sendCompleted];
            }];
          }
        } else {
          self.currentActiveSection = -1;
          [self.tableView reloadData];
          [subscriber sendCompleted];
        }
      } else {
        self.movies = nil;
        self.showtimes = nil;
        self.currentDateMovies = nil;
        [subscriber sendCompleted];
      }
      self.dates = [[SEADataManager sharedInstance] datesForShowtimes:self.showtimes];
      if (self.layout == SEAShowtimesLayoutTime) {
        [self.pickerView reloadData];
        if (self.view.window && self.dates.count > 0) {
          [self updatePickerView];
        } else {
          self.pickerView.city = [SEALocationManager sharedInstance].currentCity;
        }
      }
      if (self.movies.count == 0) {
        self.errorView.alpha = 0.25f;
        if (![[SEADataManager sharedInstance] citySupported]) {
          self.errorView.text = NSLocalizedString(@"К сожалению, ваш город не поддерживается.", nil);
        } else {
          self.errorView.text = NSLocalizedString(@"К сожалению, ничего не найдено.", nil);
        }
        self.errorView.verticalOffset = -self.delegate.buttonBarHeight / 2;
        [self.errorView setNeedsLayout];
      } else {
        self.errorView.alpha = 0;
      }
    }];
    return nil;
  }] replayLazily] finally:^{
    self.refreshSignal = nil;
  }];
  return self.refreshSignal;
}

#pragma mark Private

- (void)setUpPickerView {
  self.pickerView = [[SEAPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, kShowtimesPickerViewHeight)];
  self.pickerView.dataSource = self;
  self.pickerView.delegate = self;
  self.pickerView.interitemSpacing = 10;
}

- (void)setUpTableView {
  self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  if (self.layout == SEAShowtimesLayoutMovies) {
    [self.tableView registerClass:[SEAShowtimesSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];
    [self.tableView registerClass:[SEAShowtimesCarouselWithLabel class] forCellReuseIdentifier:NSStringFromClass([SEAShowtimesCarouselWithLabel class])];
  } else {
    [self.tableView registerClass:[SEAShowtimesList class] forCellReuseIdentifier:NSStringFromClass([SEAShowtimesList class])];
  }
  if (self.pickerView) {
    self.tableView.tableHeaderView = self.pickerView;
  }
  [self.view addSubview:self.tableView];

  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
  [self.tableView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setUpErrorView {
  self.errorView = [[SEAErrorView alloc] initWithFrame:self.view.bounds image:[UIImage imageNamed:@"SadFace"] text:@"" reloadBlock:nil];
  self.errorView.alpha = 0;
  [self.view addSubview:self.errorView];
}

- (void)updatePickerView {
  if ([self.pickerView.city isEqualToString:[SEALocationManager sharedInstance].currentCity] && ([self currentDateItem] == self.pickerView.selectedItem || self.pickerView.didMoveManually)) {
    return;
  }

  self.pickerView.city = [SEALocationManager sharedInstance].currentCity;
  if (self.pickerView.collectionView.numberOfSections > 0 && ![self.pickerView.city isEqualToString:[SEALocationManager sharedInstance].currentCity]) {
    self.pickerView.selectOnScroll = NO;
    [self.dates enumerateObjectsUsingBlock:^(NSDate *date, NSUInteger idx, BOOL *stop) {
      if ([SEADataManager hasPassed:date]) {
        [self.pickerView scrollToItem:idx animated:NO];
        *stop = YES;
      }
      if (idx == self.dates.count - 1) {
        [self.pickerView scrollToItem:idx animated:NO];
      }
    }];
    [self performSelector:@selector(selectCurrentTimeInterval) withObject:nil afterDelay:0.2f];
  } else {
    [self selectCurrentTimeInterval];
  }
}

- (void)selectCurrentTimeInterval {
  self.pickerView.selectOnScroll = YES;
  [self.dates enumerateObjectsUsingBlock:^(NSDate *date, NSUInteger idx, BOOL *stop) {
    if (![SEADataManager hasPassed:date]) {
      [self.pickerView selectItem:idx animated:YES];
      *stop = YES;
    }
    if (idx == self.dates.count - 1) {
      [self.pickerView selectItem:idx animated:YES];
    }
  }];
}

- (NSUInteger)currentDateItem {
  for (NSUInteger i = 0; i < self.dates.count; i++) {
    if (![SEADataManager hasPassed:self.dates[i]]) {
      return i;
    }
  }
  return NSNotFound;
}

- (void)backgroundTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
  CGPoint tapLocation = [tapGestureRecognizer locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
  if (indexPath || CGRectContainsPoint(self.pickerView.frame, tapLocation)) {
    tapGestureRecognizer.cancelsTouchesInView = NO;
  } else {
    [self hideVisiblePopTip];
  }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (self.layout == SEAShowtimesLayoutMovies) {
    return (NSInteger)self.movies.count;
  } else {
    return 1;
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (self.layout == SEAShowtimesLayoutMovies) {
    if (self.currentActiveSection == section) {
      SEAMovie *movie = self.movies[(NSUInteger)section];
      return (NSInteger)[[SEADataManager sharedInstance] localTheatresForMovie:movie].count;
    } else {
      return 0;
    }
  } else {
    return (NSInteger)self.currentDateMovies.count;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (self.layout == SEAShowtimesLayoutMovies) {
    return kMovieSectionHeaderViewHeight;
  } else {
    return 0;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.layout == SEAShowtimesLayoutMovies) {
    return kShowtimesCarouselHeight + kShowtimesCarouselLabelHeight;
  } else {
    return kShowtimesListCellHeight;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.layout == SEAShowtimesLayoutMovies) {
    SEAShowtimesCarouselWithLabel *cell = (SEAShowtimesCarouselWithLabel *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEAShowtimesCarouselWithLabel class]) forIndexPath:indexPath];
    cell.containerView = tableView;
    cell.currentLayout = self.layout;
    cell.popTipDelegate = self;
    SEAMovie *movie = self.movies[(NSUInteger)indexPath.section];
    cell.theatre = [[SEADataManager sharedInstance] localTheatresForMovie:movie][(NSUInteger)indexPath.row];
    cell.movie = movie;
    [self.cells addObject:cell];
    return cell;
  } else {
    SEAShowtimesList *cell = (SEAShowtimesList *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEAShowtimesList class]) forIndexPath:indexPath];
    cell.containerView = tableView;
    cell.popTipDelegate = self;
    cell.delegate = self;
    SEAMovie *movie = self.currentDateMovies[(NSUInteger)indexPath.row];
    cell.movie = movie;
    cell.showtimes = [SEADataManager filterShowtimes:[SEADataManager filterShowtimes:self.showtimes date:self.currentDate] movieId:movie.id];
    [self.cells addObject:cell];
    return cell;
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (self.layout == SEAShowtimesLayoutMovies) {
    SEAShowtimesSectionHeaderView *headerView = (SEAShowtimesSectionHeaderView *)[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];
    headerView.delegate = self;
    headerView.movie = self.movies[(NSUInteger)section];
    [headerView setUpArrowIconWithOrientation:SEAArrowIconOrientationHorizontal];
    return headerView;
  } else {
    return nil;
  }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.layout == SEAShowtimesLayoutMovies) {
    [self.delegate setHideTabBar:YES];
    SEAShowtimesCarousel *cell = (SEAShowtimesCarousel *)[self.tableView cellForRowAtIndexPath:indexPath];
    SEATheatreViewController *theatreViewController = [[SEATheatreViewController alloc] initWithTheatre:cell.theatre];
    [self.navigationController pushViewController:theatreViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
  }
}

#pragma mark SEAShowtimesSectionHeaderViewDelegate

- (void)sectionHeaderViewBackdropTapped:(SEAShowtimesSectionHeaderView *)headerView {
  [self hideVisiblePopTip];
  NSInteger section = (NSInteger)[self.movies indexOfObject:headerView.movie];
  self.previousActiveSection = self.currentActiveSection;
  self.previousActiveSectionHeaderView = self.currentActiveSectionHeaderView;
  if (self.currentActiveSection == section) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.previousActiveSection] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self collapsePreviousActiveSectionWithCompletion:nil];
  } else if (self.currentActiveSection >= 0) {
    [self collapsePreviousActiveSectionWithCompletion:^{
      self.currentActiveSection = section;
      self.currentActiveSectionHeaderView = headerView;
      [self toggleCurrentActiveSectionWithCompletion:nil];
    }];
  } else {
    self.currentActiveSection = section;
    self.currentActiveSectionHeaderView = headerView;
    [self toggleCurrentActiveSectionWithCompletion:nil];
  }
}

- (void)toggleCurrentActiveSectionWithCompletion:(void (^)())completion {
  if (self.currentActiveSection >= 0) {
    [self toggleSection:(NSUInteger)self.currentActiveSection completion:completion];
  } else if (completion) {
    completion();
  }
}

- (void)collapsePreviousActiveSectionWithCompletion:(void (^)())completion {
  if (self.previousActiveSection >= 0) {
    self.currentActiveSection = -1;
    self.previousActiveSectionHeaderView = self.currentActiveSectionHeaderView;
    self.currentActiveSectionHeaderView = nil;
    [self toggleSection:(NSUInteger)self.previousActiveSection completion:completion];
  } else if (completion) {
    completion();
  }
}

- (void)toggleSection:(NSUInteger)section completion:(void (^)())completion {
  void (^toggleCompletion)() = ^{
    self.tableView.userInteractionEnabled = YES;
    if (self.currentActiveSection >= 0) {
      [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.currentActiveSection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    if (completion) {
      completion();
    }
  };
  self.tableView.userInteractionEnabled = NO;

  if (self.selectedDate != [SEADataManager sharedInstance].selectedDate) {
    [self.previousActiveSectionHeaderView.arrowIcon pointDownAnimated:YES];
    [self.previousActiveSectionHeaderView stopFloatAnimation];
    [self.tableView beginUpdates];
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:(NSInteger)section]; row++) {
      [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:(NSInteger)section]];
    }
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [CATransaction setCompletionBlock:toggleCompletion];
    [self.tableView endUpdates];
    return;
  }

  SEAMovie *movie = self.movies[section];
  NSArray *currentArray = @[];
  NSArray *previousArray = @[];

  if (self.currentActiveSection >= 0) {
    currentArray = [[SEADataManager sharedInstance] theatresForMovie:movie city:self.city];
    [self.currentActiveSectionHeaderView.arrowIcon pointUpAnimated:YES];
    [self.currentActiveSectionHeaderView startFloatAnimation];
    [self.delegate setPercentHidden:1 interactive:NO];
  } else {
    previousArray = [[SEADataManager sharedInstance] theatresForMovie:movie city:self.city];
    [self.previousActiveSectionHeaderView.arrowIcon pointDownAnimated:YES];
    [self.previousActiveSectionHeaderView stopFloatAnimation];
  }
  NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:currentArray previousArray:previousArray];
  [self.tableView wml_applyBatchChangesForRows:diffs inSection:section withRowAnimation:UITableViewRowAnimationTop completion:toggleCompletion];
}

- (void)sectionHeaderViewPosterTapped:(SEAShowtimesSectionHeaderView *)headerView {
  if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
    self.selectedHeader = headerView;
    [self.delegate setHideTabBar:YES];
    SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:headerView.movie];
    [self.navigationController pushViewController:movieViewController animated:YES];
  }
}

#pragma mark SEAShowtimesListDelegate

- (void)cellPosterTapped:(SEAShowtimesList *)cell {
  if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
    self.selectedCell = cell;
    [self.delegate setHideTabBar:YES];
    SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:cell.movie];
    [self.navigationController pushViewController:movieViewController animated:YES];
  }
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

#pragma mark XLPagerTabStripViewControllerDelegate

- (NSString *)titleForPagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController {
  return (self.layout == SEAShowtimesLayoutMovies) ? NSLocalizedString(@"По фильму", nil) : NSLocalizedString(@"По времени", nil);
}

#pragma mark SEAPickerViewDataSource

- (NSUInteger)numberOfItemsInPickerView:(SEAPickerView *)pickerView {
  return self.dates.count;
}

- (NSDate *)pickerView:(SEAPickerView *)pickerView dateForItem:(NSInteger)item {
  return self.dates[(NSUInteger)item];
}

#pragma mark SEAPickerViewDelegate

- (void)pickerView:(SEAPickerView *)pickerView didSelectItem:(NSInteger)item {
  [self hideVisiblePopTip];
  UITableViewRowAnimation animation = UITableViewRowAnimationLeft;
  if ([(NSDate *)self.dates[(NSUInteger)item] compare:self.currentDate] == NSOrderedDescending) {
    animation = UITableViewRowAnimationRight;
  }
  NSArray *oldTimeIntervalMovies = self.currentDateMovies;
  self.currentDate = self.dates[(NSUInteger)item];
  self.currentDateMovies = [[SEADataManager sharedInstance] sortedMovies:[[SEADataManager sharedInstance] moviesForShowtimes:[SEADataManager filterShowtimes:self.showtimes date:self.currentDate]]];
  NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.currentDateMovies previousArray:oldTimeIntervalMovies];
  [self.tableView wml_applyBatchChangesForRows:diffs inSection:0 withRowAnimation:animation completion:^{
    [self.tableView reloadData];
  }];
}

@end
