#import "SEATheatresViewController.h"

#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "SEAMainTabBarController.h"
#import "SEAMapViewController.h"
#import "SEAShowtimesSectionHeaderView.h"
#import "SEATheatreViewController.h"
#import <Analytics/Analytics.h>
#import <Doppelganger/Doppelganger.h>

@interface SEATheatresViewController () <SEAShowtimesSectionHeaderViewDelegate>

@property (nonatomic) NSArray *theatres;
@property (nonatomic) RACSignal *refreshSignal;

@end

@implementation SEATheatresViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpNavigationBarButtons];
  [[SEGAnalytics sharedAnalytics] screen:@"Theatres"];
}

#pragma mark Getters

- (UITableView *)tableView {
  UITableView *tableView = [super tableView];
  if (![tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])]) {
    [tableView registerClass:[SEAShowtimesSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];
  }
  return tableView;
}

#pragma mark Public

- (RACSignal *)refresh {
  if (self.refreshSignal) {
    return self.refreshSignal;
  }
  self.refreshSignal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSArray *oldTheatres = self.theatres;
    self.theatres = [[SEADataManager sharedInstance] sortedTheatres:[[SEADataManager sharedInstance] theatresForCity:[SEALocationManager sharedInstance].currentCity]];
    if (self.isViewLoaded && self.view.window) {
      NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.theatres previousArray:oldTheatres];
      [self.tableView wml_applyBatchChangesForSections:diffs withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
        [subscriber sendCompleted];
      }];
    } else {
      [self.tableView reloadData];
      [subscriber sendCompleted];
    }
    if (self.theatres.count == 0) {
      for (UIBarButtonItem *barButtonItem in self.navigationItem.leftBarButtonItems) {
        barButtonItem.enabled = NO;
      }
      self.errorView.alpha = 0.25f;
      self.errorView.text = NSLocalizedString(@"К сожалению, ваш город не поддерживается.", nil);
      [self.errorView setNeedsLayout];
    } else {
      for (UIBarButtonItem *barButtonItem in self.navigationItem.leftBarButtonItems) {
        barButtonItem.enabled = YES;
      }
      self.errorView.alpha = 0;
    }
    return nil;
  }] replayLazily] finally:^{
    self.refreshSignal = nil;
  }];
  return self.refreshSignal;
}

#pragma mark Private

- (void)setUpNavigationBarButtons {
  UIButton *sortButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];

  [sortButton setBackgroundImage:[[UIImage imageNamed:@"SortIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [sortButton addTarget:self action:@selector(openSortView) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *sortButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sortButton];

  UIButton *mapsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [mapsButton setBackgroundImage:[[UIImage imageNamed:@"MapIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [mapsButton addTarget:self action:@selector(openMaps) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *mapsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mapsButton];

  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
  space.width = 15;

  self.navigationItem.leftBarButtonItems = @[sortButtonItem, space, mapsButtonItem];
}

- (void)openSortView {
  SEAActionSheet *actionSheet = [[SEAActionSheet alloc] initWithTitle:NSLocalizedString(@"Сортировать кинотеатры", nil)];

  if (![[SEALocationManager sharedInstance].actualCity isEqualToString:[SEALocationManager sharedInstance].currentCity]) {
    actionSheet.disabledIndex = SEATheatresSortByDistance;
  }
  if ([[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kTheatresSortByKey] == SEATheatresSortByDistance && actionSheet.disabledIndex == SEATheatresSortByDistance) {
    actionSheet.activeIndex = SEATheatresSortByShowtimesCount;
  } else {
    actionSheet.activeIndex = (NSUInteger)[[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kTheatresSortByKey];
  }

  void (^buttonClicked)(SEATheatresSortBy) = ^(SEATheatresSortBy sortBy) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setInteger:sortBy forKey:kTheatresSortByKey];
    [[SEAMainTabBarController sharedInstance] refreshTheatres];
  };
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По названию", nil) image:[UIImage imageNamed:@"SortByName"] handler:^{
    buttonClicked(SEATheatresSortByName);
  }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По расстоянию", nil) image:[UIImage imageNamed:@"SortByDistance"] handler:^{
    buttonClicked(SEATheatresSortByDistance);
  }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По средней цене билета", nil) image:[UIImage imageNamed:@"SortByPrice"] handler:^{
    buttonClicked(SEATheatresSortByPrice);
  }];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"По количеству сеансов", nil) image:[UIImage imageNamed:@"SortByShowtimesCount"] handler:^{
    buttonClicked(SEATheatresSortByShowtimesCount);
  }];

  [actionSheet show];
}

- (void)openMaps {
  NSString *city = [[SEADataManager sharedInstance] citySupported] ? [SEALocationManager sharedInstance].currentCity : NSLocalizedString(@"Не найдено", nil);

  [[SEGAnalytics sharedAnalytics] track:@"Opened the map" properties:@{
     @"from" : @"Showtimes",
     @"city" : city
   }];
  self.hideTabBar = YES;
  [self.navigationController pushViewController:[SEAMapViewController sharedInstance] animated:YES];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.theatres.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return kTheatreSectionHeaderViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  SEAShowtimesSectionHeaderView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([SEAShowtimesSectionHeaderView class])];

  headerView.delegate = self;
  headerView.theatre = self.theatres[(NSUInteger)section];
  [headerView setUpArrowIconWithOrientation:SEAArrowIconOrientationVertical];
  return headerView;
}

#pragma mark SEAShowtimesSectionHeaderViewDelegate

- (void)sectionHeaderViewBackdropTapped:(SEAShowtimesSectionHeaderView *)headerView {
  self.hideTabBar = YES;
  SEATheatreViewController *theatreViewController = [[SEATheatreViewController alloc] initWithTheatre:headerView.theatre];
  [self.navigationController pushViewController:theatreViewController animated:YES];
}

- (void)sectionHeaderViewStarred:(SEAShowtimesSectionHeaderView *)headerView {
  [[SEADataManager sharedInstance] saveStarredTheatresIds];
  [[SEAMainTabBarController sharedInstance] refreshTheatres];
  [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
}

@end
