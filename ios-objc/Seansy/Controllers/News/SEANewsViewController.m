#import "SEANewsViewController.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEANewsEntry.h"
#import "SEANewsEntryCell.h"
#import "SEAWebViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <Doppelganger/Doppelganger.h>

static NSUInteger const kMaxNewsCount = 100;

@interface SEANewsViewController ()

@property (nonatomic) NSArray *news;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, getter = isReloading) BOOL reloading;
@property (nonatomic) RACSignal *refreshSignal;

@end

@implementation SEANewsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  [[SEGAnalytics sharedAnalytics] screen:@"News"];
}

#pragma mark Getters

- (UITableView *)tableView {
  UITableView *tableView = [super tableView];
  if (![tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEANewsEntryCell class])]) {
    [tableView registerClass:[SEANewsEntryCell class] forCellReuseIdentifier:NSStringFromClass([SEANewsEntryCell class])];
  }
  if (!self.refreshControl) {
    self.refreshControl = [UIRefreshControl new];
    self.refreshControl.tintColor = [UIColor colorWithHexString:kAmberColor];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:self.refreshControl];
  }
  return tableView;
}

#pragma mark Public

- (void)reload {
  if (self.isReloading) {
    return;
  }
  self.reloading = YES;
  [[[[[SEADataManager sharedInstance] reloadNews] then:^RACSignal *{
    return [self refresh];
  }] finally:^{
    [self finishRefreshing];
    self.reloading = NO;
  }] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed news view");
  }];
}

- (RACSignal *)refresh {
  if (self.refreshSignal) {
    return self.refreshSignal;
  }
  self.refreshSignal = [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSArray *oldNews = self.news;
    NSArray *newNews = [SEADataManager newsSortedByDate:[SEADataManager sharedInstance].news];
    self.news = [newNews subarrayWithRange:NSMakeRange(0, MIN(newNews.count, kMaxNewsCount))];
    if (self.isViewLoaded && self.view.window) {
      NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.news previousArray:oldNews];
      [self.tableView wml_applyBatchChangesForRows:diffs inSection:0 withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
        [self.tableView reloadData];
        [subscriber sendCompleted];
      }];
    } else {
      [self.tableView reloadData];
      [subscriber sendCompleted];
    }
    return nil;
  }] doCompleted:^{
    if (self.news.count == 0) {
      self.errorView.alpha = 0.25f;
      self.errorView.text = NSLocalizedString(@"К сожалению, новости загрузить не удалось.", nil);
      [self.errorView setNeedsLayout];
    } else {
      self.errorView.alpha = 0;
    }
  }] replayLazily] finally:^{
    self.refreshSignal = nil;
  }];
  return self.refreshSignal;
}

- (void)finishRefreshing {
  if (self.refreshControl.isRefreshing) {
    [self.refreshControl endRefreshing];
  }
}

#pragma mark Private

- (void)appearAnimation {
  if (self.news.count > 0) {
    __block NSUInteger visibleCellsCount = self.tableView.visibleCells.count;
    void (^cellAnimation)(id, NSUInteger, BOOL *) = ^(UIView *view, NSUInteger idx, BOOL *stop) {
      NSTimeInterval delay = ((CGFloat)idx / (CGFloat)visibleCellsCount) * 0.15f;
      view.transform = CGAffineTransformMakeTranslation(-self.view.width, 0);
      void (^animation)() = ^{
        view.transform = CGAffineTransformIdentity;
        view.alpha = 1;
      };
      [UIView animateWithDuration:0.65f delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:animation completion:nil];
    };
    [self.tableView.visibleCells enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:cellAnimation];
  }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.news.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kNewsEntryCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SEANewsEntryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEANewsEntryCell class])];
  cell.newsEntry = (SEANewsEntry *)self.news[(NSUInteger)indexPath.row];
  cell.parallaxRatio = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kParallaxKey] ? 1.5f : 1;

  return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SEANewsEntry *newsEntry = (SEANewsEntry *)self.news[(NSUInteger)indexPath.row];
  SEAWebViewController *webViewController = [[SEAWebViewController alloc] initWithUrl:newsEntry.link];
  [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  SEANewsEntryCell *cell = (SEANewsEntryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  cell.highlighted = YES;
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  SEANewsEntryCell *cell = (SEANewsEntryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  cell.highlighted = NO;
}

@end
