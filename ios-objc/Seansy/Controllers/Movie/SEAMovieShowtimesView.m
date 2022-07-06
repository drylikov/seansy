#import "SEAMovieShowtimesView.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAMainTabBarController.h"
#import "SEAShowtimeViewController.h"
#import "SEATheatreViewController.h"
#import "SEATicketonViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <Doppelganger/Doppelganger.h>

@interface SEAMovieShowtimesView ()

@property (nonatomic) NSArray *theatres;
@property (nonatomic) NSMutableArray *cells;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, getter = isAnimatingPopTip) BOOL animatingPopTip;
@property (weak, nonatomic) SEAMovie *movie;
@property (weak, nonatomic) AMPopTip *visiblePopTip;

@end

@implementation SEAMovieShowtimesView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame movie:(SEAMovie *)movie {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.movie = movie;
  [self setUpTableView];

  return self;
}

#pragma mark Private

- (void)setUpTableView {
  self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.allowsSelection = NO;
  self.tableView.backgroundColor = [UIColor clearColor];
  [self.tableView registerClass:[SEAShowtimesSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];
  [self.tableView registerClass:[SEAShowtimesCarousel class] forCellReuseIdentifier:NSStringFromClass([SEAShowtimesCarousel class])];
  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
  [self.tableView addGestureRecognizer:self.tapGestureRecognizer];
  [self addSubview:self.tableView];
}

#pragma mark Public

- (void)refresh {
  [self hideVisiblePopTip];

  NSArray *oldTheatres = self.theatres;
  self.theatres = [[SEADataManager sharedInstance] localTheatresForMovie:self.movie];
  if (oldTheatres.count == self.theatres.count) {
    NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.theatres previousArray:oldTheatres];
    [self.tableView wml_applyBatchChangesForSections:diffs withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
      self.cells = [NSMutableArray new];
      [self.tableView reloadData];
    }];
  } else {
    self.cells = [NSMutableArray new];
    [self.tableView reloadData];
  }

  if (oldTheatres.count == 0) {
    [self.tableView layoutIfNeeded];
    self.tableView.height = self.tableView.contentSize.height;
    self.height = self.tableView.height;
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

#pragma mark Gesture recognizer

- (void)backgroundTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
  CGPoint tapLocation = [tapGestureRecognizer locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];

  if (indexPath) {
    tapGestureRecognizer.cancelsTouchesInView = NO;
  } else {
    [self hideVisiblePopTip];
  }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.theatres.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return kTheatreSectionHeaderViewHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kShowtimesCarouselHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  SEAShowtimesSectionHeaderView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];

  headerView.delegate = self;
  headerView.theatre = self.theatres[(NSUInteger)section];
  [headerView setUpArrowIconWithOrientation:SEAArrowIconOrientationVertical];
  return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SEAShowtimesCarousel *cell = (SEAShowtimesCarousel *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEAShowtimesCarousel class]) forIndexPath:indexPath];

  cell.popTipDelegate = self;
  cell.containerView = self.containerView;
  cell.currentLayout = SEAShowtimesLayoutTheatres;
  cell.theatre = self.theatres[(NSUInteger)indexPath.section];
  cell.movie = self.movie;
  [self.movie.backdrop getColorsWithCompletionBlock:^(NSDictionary *colors) {
    cell.color = colors[kBackdropTextColorKey];
  }];
  [self.cells addObject:cell];
  return cell;
}

#pragma mark SEAShowtimesSectionHeaderViewDelegate

- (void)sectionHeaderViewBackdropTapped:(SEAShowtimesSectionHeaderView *)headerView {
  if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
    SEATheatreViewController *theatreViewController = [[SEATheatreViewController alloc] initWithTheatre:headerView.theatre];
    [self.delegate.navigationController pushViewController:theatreViewController animated:YES];
  }
}

- (void)sectionHeaderViewStarred:(SEAShowtimesSectionHeaderView *)headerView {
  [[SEADataManager sharedInstance] saveStarredTheatresIds];
  [[SEAMainTabBarController sharedInstance] refreshTheatres];
  [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
  [self refresh];
}

#pragma mark ShowtimesCarouselDelegate

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
  [self.delegate.navigationController presentViewController:showtimeViewController animated:YES completion:nil];
}

- (void)buyTicketForShowtime:(SEAShowtime *)showtime {
  SEATicketonViewController *ticketonViewController = [[SEATicketonViewController alloc] initWithShowtime:showtime];
  [self.delegate.navigationController presentViewController:ticketonViewController animated:YES completion:nil];
}

@end
