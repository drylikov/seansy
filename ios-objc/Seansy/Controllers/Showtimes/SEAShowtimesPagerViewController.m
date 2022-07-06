#import "SEAShowtimesPagerViewController.h"

#import "SEAShowtimesItemCell.h"
#import "SEAShowtimesSectionHeaderView.h"
#import "SEAShowtimesPagerChildItemViewController.h"

@interface SEAShowtimesPagerViewController ()

@property (nonatomic) BOOL loaded;
@property (nonatomic) SEAShowtimesPagerChildItemViewController *moviesLayoutShowtimesViewController;
@property (nonatomic) SEAShowtimesPagerChildItemViewController *timeLayoutShowtimesViewController;

@end

@implementation SEAShowtimesPagerViewController

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.moviesLayoutShowtimesViewController = [[SEAShowtimesPagerChildItemViewController alloc] initWithLayout:SEAShowtimesLayoutMovies];
  self.moviesLayoutShowtimesViewController.delegate = self;

  self.timeLayoutShowtimesViewController = [[SEAShowtimesPagerChildItemViewController alloc] initWithLayout:SEAShowtimesLayoutTime];
  self.timeLayoutShowtimesViewController.delegate = self;

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  __weak typeof(self) weakSelf = self;
  self.changeCurrentIndexProgressiveBlock = ^(XLButtonBarViewCell *oldCell, XLButtonBarViewCell *newCell, CGFloat progressPercentage, BOOL changeCurrentIndex, BOOL animated) {
    if (changeCurrentIndex) {
      oldCell.label.textColor = [UIColor colorWithWhite:1 alpha:0.6f];
      newCell.label.textColor = [UIColor whiteColor];
    }
    [weakSelf.activeChildItemViewController hideVisiblePopTip];
  };
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (!self.loaded) {
    self.loaded = YES;
    [self refresh];
  }
  [self.view layoutIfNeeded];
}

#pragma mark Public

- (RACSignal *)refresh {
  return [RACSignal merge:@[
            [self.moviesLayoutShowtimesViewController refresh],
            [self.timeLayoutShowtimesViewController refresh]
          ]];
}

- (UIScrollView *)activeScrollView {
  return self.activeChildItemViewController.tableView;
}

- (id<SEAPosterViewDelegate>)lastSelectedPosterView {
  if (self.currentIndex == 0) {
    return self.moviesLayoutShowtimesViewController.selectedHeader;
  } else {
    return self.timeLayoutShowtimesViewController.selectedCell;
  }
}

- (void)showActionSheet:(SEAActionSheet *)actionSheet {
  if (self.activeChildItemViewController.visiblePopTip) {
    __weak typeof(self) weakSelf = self;
    void (^oldDismissHandler)() = self.activeChildItemViewController.visiblePopTip.dismissHandler;
    self.activeChildItemViewController.visiblePopTip.dismissHandler = ^{
      oldDismissHandler();
      weakSelf.activeChildItemViewController.visiblePopTip = nil;
      [actionSheet show];
    };
    [self.activeChildItemViewController.visiblePopTip hide];
  } else {
    [actionSheet show];
  }
}

#pragma mark Private

- (SEAShowtimesPagerChildItemViewController *)activeChildItemViewController {
  if (self.currentIndex == 0) {
    return self.moviesLayoutShowtimesViewController;
  } else {
    return self.timeLayoutShowtimesViewController;
  }
}

#pragma mark XLPagerTabStripViewControllerDataSource

- (NSArray *)childViewControllersForPagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController {
  return @[self.moviesLayoutShowtimesViewController, self.timeLayoutShowtimesViewController];
}

@end
