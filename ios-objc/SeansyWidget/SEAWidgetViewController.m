#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "SEAMoviesTableViewCell.h"
#import "SEAWidgetViewController.h"
#import "UIView+AYUtils.h"
#import <NotificationCenter/NotificationCenter.h>

static NSString *const kWidgetLastUpdatedKey = @"widgetLastUpdated";

@interface SEAWidgetViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *moviesTableView;
@property (nonatomic) UILabel *errorLabel;
@property (nonatomic) NSArray *movies;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, copy) void (^completionHandler)(NCUpdateResult);
@property (nonatomic) BOOL hasSignaled;
@property (nonatomic) RACSignal *dataSignal;

@end

@implementation SEAWidgetViewController

#pragma mark Lifecycle

- (void)loadView {
  self.view = [UIView new];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self updateSize];
  [self.dataSignal subscribeError:^(NSError *error) {
    DDLogError(@"Error occured while loading data: %@", error);
  }];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if (!self.hasSignaled) {
    [self signalComplete:NCUpdateResultFailed];
  }
}

#pragma mark Getters

- (UITableView *)moviesTableView {
  if (_moviesTableView) {
    return _moviesTableView;
  }
  _moviesTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
  _moviesTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _moviesTableView.delegate = self;
  _moviesTableView.dataSource = self;
  _moviesTableView.showsVerticalScrollIndicator = NO;
  _moviesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [_moviesTableView registerClass:[SEAMoviesTableViewCell class] forCellReuseIdentifier:NSStringFromClass([SEAMoviesTableViewCell class])];
  [self.view addSubview:_moviesTableView];
  return _moviesTableView;
}

- (UIActivityIndicatorView *)activityIndicatorView {
  if (_activityIndicatorView) {
    _activityIndicatorView.center = self.view.center;
    return _activityIndicatorView;
  }
  _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  _activityIndicatorView.center = self.view.center;
  [self.view addSubview:_activityIndicatorView];
  return _activityIndicatorView;
}

- (UILabel *)errorLabel {
  if (_errorLabel) {
    _errorLabel.center = self.view.center;
    return _errorLabel;
  }
  _errorLabel = [UILabel new];
  _errorLabel.textColor = [UIColor whiteColor];
  _errorLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
  _errorLabel.text = NSLocalizedString(@"Произошла ошибка при обновлении", nil);
  [_errorLabel sizeToFit];
  _errorLabel.center = self.view.center;
  _errorLabel.alpha = 0;
  [self.view addSubview:_errorLabel];
  return _errorLabel;
}

- (RACSignal *)dataSignal {
  if (_dataSignal) {
    return _dataSignal;
  }
  _dataSignal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [self updateSize];
    self.errorLabel.alpha = 0;
    if (self.movies.count == 0) {
      [self.activityIndicatorView startAnimating];
    }
    [[SEALocationManager sharedInstance] restoreCity];
    DDLogVerbose(@"Getting new data");
    NSDate *offlineDataExpirationDate = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kOfflineDataExpirationDateKey];
    BOOL fromCache = offlineDataExpirationDate ? [[NSDate date] compare : offlineDataExpirationDate] == NSOrderedAscending : NO;
    [[[[[SEADataManager sharedInstance] loadDataFromCache:fromCache] deliverOn:RACScheduler.mainThreadScheduler] doCompleted:^{
      NSArray *movies = [SEADataManager moviesSortedByPopularity:[SEADataManager sharedInstance].nowPlayingMovies];
      self.movies = [movies subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)5, movies.count))];
      [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[NSDate date] forKey:kWidgetLastUpdatedKey];
    }] subscribe:subscriber];
    return nil;
  }] replayLazily] finally:^{
    [self updateSize];
    [self.activityIndicatorView stopAnimating];
    self->_dataSignal = nil;
    if (self.movies.count == 0) {
      self.errorLabel.alpha = 1;
    }
    [self.moviesTableView reloadData];
  }];
  return _dataSignal;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.movies.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kMoviesTableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SEAMoviesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEAMoviesTableViewCell class]) forIndexPath:indexPath];
  cell.movie = self.movies[(NSUInteger)indexPath.row];
  return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SEAMovie *movie = self.movies[(NSUInteger)indexPath.row];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"seansy://movie-%@", @(movie.id)]];
  [self.extensionContext openURL:url completionHandler:nil];
  [self.moviesTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Private

- (void)signalComplete:(NCUpdateResult)updateResult {
  self.hasSignaled = YES;
  DDLogVerbose(@"Sending widget update result");
  if (self.completionHandler) {
    self.completionHandler(updateResult);
    self.completionHandler = nil;
  }
}

- (void)updateSize {
  self.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), self.movies.count > 0 ? self.movies.count * kMoviesTableViewCellHeight : 44);
  self.preferredContentSize = self.view.frame.size;
}

#pragma mark NCWidgetProviding

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
  defaultMarginInsets.bottom = 0;
  defaultMarginInsets.left = 0;
  defaultMarginInsets.right = 0;
  return defaultMarginInsets;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  self.completionHandler = completionHandler;
  self.hasSignaled = NO;
  NSDate *lastUpdated = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kWidgetLastUpdatedKey];
  if ([[NSDate date] timeIntervalSinceDate:lastUpdated] < 5 * 60 && self.movies.count > 0) {
    DDLogInfo(@"Widget up to date");
    [self signalComplete:NCUpdateResultNoData];
  } else {
    [self.dataSignal subscribeError:^(NSError *error) {
      DDLogError(@"Error occured while loading data: %@", error);
      [self signalComplete:NCUpdateResultFailed];
    } completed:^{
      [self signalComplete:NCUpdateResultNewData];
    }];
  }
}

@end
