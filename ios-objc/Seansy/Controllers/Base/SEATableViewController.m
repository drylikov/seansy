#import "SEATableViewController.h"

#import "SEAConstants.h"
#import "SEAMainTabBarController.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <AYSlidingPickerView/AYSlidingPickerView.h>

@interface SEATableViewController ()

@property (nonatomic) CGFloat dragStartPosition;
@property (nonatomic) CGFloat percentHidden;
@property (nonatomic, getter = isAnimatingBars) BOOL animatingBars;
@property (nonatomic, getter = isDragging) BOOL dragging;
@property (nonatomic, getter = isLoaded) BOOL loaded;
@property (nonatomic, getter = isVisible) BOOL visible;

@end

@implementation SEATableViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = nil;
  if (!self.isLoaded) {
    self.loaded = YES;
    [self refresh];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.visible = YES;
  [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0 options:0 animations:^{
    self.tabBarController.tabBar.top = self.navigationController.view.bottom - self.tabBarController.tabBar.height;
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

#pragma mark Getters

- (UITableView *)tableView {
  if (_tableView) {
    return _tableView;
  }
  _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
  _tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.height, 0, self.tabBarController.tabBar.height, 0);
  _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.navigationController.navigationBar.height, 0, self.tabBarController.tabBar.height, 0);
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  _tableView.separatorColor = [UIColor colorWithHexString:kOnyxColor];
  _tableView.separatorInset = UIEdgeInsetsZero;
  [self.view addSubview:_tableView];

  return _tableView;
}

- (SEAErrorView *)errorView {
  if (_errorView) {
    return _errorView;
  }
  _errorView = [[SEAErrorView alloc] initWithFrame:self.view.bounds image:[UIImage imageNamed:@"SadFace"]  text:@"" reloadBlock:nil];
  _errorView.alpha = 0;
  [self.view addSubview:_errorView];

  return _errorView;
}

#pragma mark Public

- (RACSignal *)refresh {
  return [RACSignal empty];
}

- (void)restoreBars {
  [self restoreBarsAnimated:NO];
}

#pragma mark Private

- (void)setPercentHidden:(CGFloat)percentHidden interactive:(BOOL)interactive {
  percentHidden = MAX(0, MIN(1, percentHidden));
  if (percentHidden == self.percentHidden) {
    return;
  }
  self.percentHidden = percentHidden;
  [self updateBarsAnimated:!interactive];
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
  CGFloat toBottom = self.tableView.contentSize.height - self.tableView.height - self.tableView.contentOffset.y - self.tableView.contentInset.top;

  if (self.navigationController.navigationBar.top < 0 && self.percentHidden == 0 && toBottom <= 0) {
    self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + self.navigationController.navigationBar.height);
  }

  if (self.tabBarController.tabBar.top == self.navigationController.view.bottom && self.percentHidden == 0 && toBottom <= 0) {
    self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + self.tabBarController.tabBar.height);
  }

  self.navigationController.navigationBar.top = -self.navigationController.navigationBar.height * self.percentHidden;
  if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
    self.tableView.top = MAX(self.navigationController.navigationBar.bottom, 0);
    self.tableView.height = self.view.height - MAX(self.navigationController.navigationBar.bottom, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height * (1 - self.percentHidden), 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height * (1 - self.percentHidden), 0);
  } else {
    self.navigationController.navigationBar.top += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) * (1 - self.percentHidden);
    self.tableView.top = MAX(self.navigationController.navigationBar.bottom, 0) + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) * self.percentHidden;
    self.tableView.height = self.view.height - MAX(self.navigationController.navigationBar.bottom, 0) - CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) * self.percentHidden;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.height, 0);
  }

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

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.dragStartPosition = (CGFloat)MAX(scrollView.contentOffset.y + scrollView.contentInset.top, 0);
  self.dragging = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  CGFloat position = targetContentOffset->y + scrollView.contentInset.top;

  if (self.isDragging) {
    self.dragging = NO;
    CGFloat diff = position - self.dragStartPosition;
    if (diff <= -self.navigationController.navigationBar.height / 2) {
      [self setPercentHidden:0 interactive:NO];
    } else if (diff > 0 && self.percentHidden > 0 && self.percentHidden < 1) {
      [self setPercentHidden:1 interactive:NO];
    }
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat position = scrollView.contentOffset.y + scrollView.contentInset.top;
  CGFloat diff = position - self.dragStartPosition;
  CGFloat toBottom = scrollView.contentSize.height - scrollView.height - position;

  if (position < 0) {
    [self setPercentHidden:0 interactive:NO];
  } else if (self.isDragging) {
    if (toBottom <= 0) {
      [self setPercentHidden:0 interactive:NO];
    } else if (self.percentHidden < 1 && diff > 0 && !self.isAnimatingBars) {
      CGFloat newPercent = MAX(0, MIN((diff / self.navigationController.navigationBar.height), 1));
      [self setPercentHidden:newPercent interactive:YES];
    }
  }
}

@end
