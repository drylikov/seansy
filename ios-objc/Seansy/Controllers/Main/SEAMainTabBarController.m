#import "SEAMainTabBarController.h"

#import "AYAppStore.h"
#import "AYFeedback.h"
#import "SEAAlertView.h"
#import "SEAAnimatedNavigationController.h"
#import "SEAAppDelegate.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAErrorView.h"
#import "SEALocationManager.h"
#import "SEAMoviesPagerViewController.h"
#import "SEANavigationBarTitleView.h"
#import "SEANewsViewController.h"
#import "SEAProgressView.h"
#import "SEAPromptView.h"
#import "SEASettingsViewController.h"
#import "SEAShowtimesPagerViewController.h"
#import "SEATabBarItemViewControllerDelegate.h"
#import "SEATheatresViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UINavigationItem+Loading.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <LGFilterView/LGFilterView.h>
#import <MessageUI/MessageUI.h>
#import <Reachability/Reachability.h>
#import <SDWebImage/SDImageCache.h>

static NSString *const kInstagramUsername = @"seansyapp";
static NSString *const kSeenInstagramAlert = @"seenInstagramAlert";

@interface SEAMainTabBarController () <SEAPromptViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) LGFilterView *dateFilterView;
@property (nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic) NSInteger movieIdToOpen;
@property (nonatomic) SEAErrorView *errorView;
@property (nonatomic) SEAMoviesPagerViewController *moviesViewController;
@property (nonatomic) SEANewsViewController *newsViewController;
@property (nonatomic) SEAProgressView *progressView;
@property (nonatomic) SEAPromptView *promptView;
@property (nonatomic) SEASettingsViewController *settingsViewController;
@property (nonatomic) SEAShowtimesPagerViewController *showtimesViewController;
@property (nonatomic) SEATheatresViewController *theatresViewController;
@property (nonatomic, getter = isConnected) BOOL connected;
@property (nonatomic, getter = isDisconnected) BOOL disconnected;
@property (nonatomic, getter = isLoading) BOOL loading;
@property (nonatomic, getter = isReloading) BOOL reloading;
@property (nonatomic, getter = isUpdated) BOOL updated;

@end

@implementation SEAMainTabBarController

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.view.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.tabBar.barStyle = UIBarStyleBlack;

  self.moviesViewController = [SEAMoviesPagerViewController new];
  self.moviesViewController.title = NSLocalizedString(@"Фильмы", nil);
  self.moviesViewController.tabBarItem.image = [[UIImage imageNamed:@"MoviesIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.moviesViewController.tabBarItem.selectedImage = [[UIImage imageNamed:@"MoviesIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  SEAAnimatedNavigationController *moviesViewNavigationController = [[SEAAnimatedNavigationController alloc] initWithRootViewController:self.moviesViewController];

  self.showtimesViewController = [SEAShowtimesPagerViewController new];
  self.showtimesViewController.title = NSLocalizedString(@"Cеансы", nil);
  self.showtimesViewController.tabBarItem.image = [[UIImage imageNamed:@"ClockIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.showtimesViewController.tabBarItem.selectedImage = [[UIImage imageNamed:@"ClockIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  SEAAnimatedNavigationController *showtimesViewNavigationController = [[SEAAnimatedNavigationController alloc] initWithRootViewController:self.showtimesViewController];

  self.theatresViewController = [SEATheatresViewController new];
  self.theatresViewController.title = NSLocalizedString(@"Кинотеатры", nil);
  self.theatresViewController.tabBarItem.image = [[UIImage imageNamed:@"FilmIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.theatresViewController.tabBarItem.selectedImage = [[UIImage imageNamed:@"FilmIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  SEAAnimatedNavigationController *theatresViewNavigationController = [[SEAAnimatedNavigationController alloc] initWithRootViewController:self.theatresViewController];

  self.newsViewController = [SEANewsViewController new];
  self.newsViewController.title = NSLocalizedString(@"Новости", nil);
  self.newsViewController.tabBarItem.image = [[UIImage imageNamed:@"NewsIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.newsViewController.tabBarItem.selectedImage = [[UIImage imageNamed:@"NewsIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  UINavigationController *newsViewNavigationController = [[UINavigationController alloc] initWithRootViewController:self.newsViewController];

  self.settingsViewController = [SEASettingsViewController new];
  self.settingsViewController.title = NSLocalizedString(@"Настройки", nil);
  self.settingsViewController.tabBarItem.image = [[UIImage imageNamed:@"SettingsIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.settingsViewController.tabBarItem.selectedImage = [[UIImage imageNamed:@"SettingsIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  SEAAnimatedNavigationController *settingsViewNavigationController = [[SEAAnimatedNavigationController alloc] initWithRootViewController:self.settingsViewController];

  self.viewControllers = @[moviesViewNavigationController, showtimesViewNavigationController, theatresViewNavigationController, newsViewNavigationController, settingsViewNavigationController];

  [self setUpNavigationBar];
  [self reload];

  [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:kNowPlayingMoviesLoadedNotification object:nil] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(id x) {
    [self refreshNowPlayingMovies];
  }];
  [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:kComingSoonMoviesLoadedNotification object:nil] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(id x) {
    [self refreshComingSoonMovies];
  }];
  [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:kTheatresLoadedNotification object:nil] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(id x) {
    [self refreshTheatres];
  }];
  [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:kNewsLoadedNotification object:nil] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(id x) {
    [self refreshNews];
  }];
  
  self.movieIdToOpen = NSNotFound;

  return self;
}

+ (SEAMainTabBarController *)sharedInstance {
  static SEAMainTabBarController *sharedInstance = nil;
  static dispatch_once_t oncePredicate;

  dispatch_once(&oncePredicate, ^{
    sharedInstance = [SEAMainTabBarController new];
  });
  return sharedInstance;
}

#pragma mark Lifecycle

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag
  completion:(void (^)(void))completion {
  [super presentViewController:viewControllerToPresent animated:flag completion:^{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    if (completion) {
      completion();
    }
  }];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  if (self.progressView.isVisible) {
    [self setUpProgressView];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self afterLoading];
}

#pragma mark Public

- (void)refreshNowPlayingMovies {
  [[self.moviesViewController refreshNowPlayingMovies] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed now playing movies view");
  }];
  [[self.showtimesViewController refresh] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed showtimes view");
  }];
}

- (void)refreshComingSoonMovies {
  [[self.moviesViewController refreshComingSoonMovies] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed coming soon movies view");
  }];
}

- (void)refreshTheatres {
  [[self.theatresViewController refresh] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed theatres view");
  }];
}

- (void)refreshNews {
  [[self.newsViewController refresh] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed news view");
  }];
}

- (void)openMovieWithId:(NSInteger)movieId {
  [(UINavigationController *)self.selectedViewController popToRootViewControllerAnimated:YES];
  if (self.moviesViewController.ready) {
    [self setSelectedIndex:0];
    [self.moviesViewController openMovieWithId:(NSInteger)movieId];
  } else {
    self.movieIdToOpen = movieId;
  }
}

#pragma mark Private

- (void)reload {
  if (self.isReloading) {
    [self setUpProgressView];
  }
  self.reloading = YES;
  Reachability *reachability = [Reachability reachabilityWithHostname:@"seansy.kz"];
  reachability.reachableBlock = ^(Reachability *reach) {
    [reach stopNotifier];
    if (!self.isConnected) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.errorView && self.errorView.superview) {
          [self setUpProgressView];
        }
        self.connected = YES;
        [self startLoading];
      });
    }
  };
  reachability.unreachableBlock = ^(Reachability *reach) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.disconnected = YES;
      [self startLoading];
    });
  };
  [reachability startNotifier];
}

- (void)startLoading {
  if (self.isLoading) {
    return;
  }
  RACSignal *dataSignal;
  RACSignal *locationSignal;

  if (self.isConnected) {
    dataSignal = [[[SEADataManager sharedInstance] loadDataFromCache:NO] catch:^RACSignal *(NSError *error) {
      DDLogVerbose(@"Retrying after 5 seconds");
      return [[[RACSignal empty] delay:5] concat:[RACSignal error:error]];
    }];
    locationSignal = [[SEALocationManager sharedInstance] getCurrentCity];
  } else if (self.isDisconnected) {
    NSDate *offlineDataExpirationDate = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kOfflineDataExpirationDateKey];
    BOOL fromCache = offlineDataExpirationDate ? [[NSDate date] compare : offlineDataExpirationDate] == NSOrderedAscending : NO;
    if (fromCache) {
      dataSignal = [[SEADataManager sharedInstance] loadDataFromCache:YES];
    } else {
      [[SEADataManager sharedInstance] clearCache];
    }
    locationSignal = [RACSignal return:nil];
  }
  if (dataSignal) {
    self.loading = YES;
    [[[[[RACSignal merge:@[locationSignal, dataSignal]] deliverOn:RACScheduler.mainThreadScheduler] finally:^{
      self.loading = NO;
    }] retry:3] subscribeError:^(NSError *error) {
      DDLogError(@"Error occured while loading data and location: %@", error);
      [self setUpLoadingErrorView];
    } completed:^{
      [[[SEADataManager sharedInstance] setUpSpotlightSearch] subscribeError:^(NSError *error) {
        DDLogError(@"Error occured while setting up spotlight: %@", error);
      }];
      [self finishLoading];
    }];
  } else {
    [self setUpNoConnectionView];
  }
}

- (void)finishLoading {
  [[SEGAnalytics sharedAnalytics] identify:[UIDevice currentDevice].identifierForVendor.UUIDString traits:@{
    @"city" : [[SEADataManager sharedInstance] citySupported] ? [SEALocationManager sharedInstance].currentCity : @"Неизвестный город"
  }];
  if ([[SEADataManager sharedInstance] citySupported]) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:[SEALocationManager sharedInstance].currentCity forKey:kCityNameKey];
  }

  for (UIViewController *viewController in @[self.moviesViewController, self.showtimesViewController, self.theatresViewController]) {
    [viewController.navigationItem stopAnimating];
    SEANavigationBarTitleView *titleView = [SEANavigationBarTitleView new];
    titleView.city = [[SEADataManager sharedInstance] citySupported] ? [SEALocationManager sharedInstance].currentCity : NSLocalizedString(@"Выберите город", nil);
    titleView.dateIndex = [SEADataManager sharedInstance].selectedDayIndex;
    viewController.navigationItem.titleView = titleView;
  }

  self.moviesViewController.ready = YES;
  self.showtimesViewController.ready = YES;
  [self setUpLocationSelector];
  [self setUpDateFilterView];
  if (self.progressView) {
    [self.progressView performFinishAnimation];
  }
  if (self.view.window) {
    [self afterLoading];
  }
}

- (void)afterLoading {
  if (self.isUpdated || !self.moviesViewController.ready) {
    return;
  }
  self.updated = YES;
  
#ifndef SNAPSHOT
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSeenInstagramAlert]) {
    NSURL *instagramURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://user?username=%@", kInstagramUsername]];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
      SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:NSLocalizedString(@"Подпишитесь на нас :)", nil) body:NSLocalizedString(@"Подпишитесь на нас в Инстаграме, чтобы оставаться в курсе последних новостей приложения!", nil) closeButtonTitle:NSLocalizedString(@"Нет, спасибо", nil)];
      [alertView addButtonWithTitle:NSLocalizedString(@"Подписаться", nil) handler:^{
        [[UIApplication sharedApplication] openURL:instagramURL];
      }];
      [alertView performSelector:@selector(show) withObject:nil afterDelay:1.5];
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSeenInstagramAlert];
    }
  }
  [self setUpPromptView];
  [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] subscribeNext:^(id x) {
    DDLogInfo(@"Checking for prompt view");
    [self setUpPromptView];
  }];
#endif
  
  if (self.movieIdToOpen != NSNotFound) {
    [self.moviesViewController openMovieWithId:self.movieIdToOpen];
    self.movieIdToOpen = NSNotFound;
  }
}

- (void)setUpProgressView {
  if (self.errorView) {
    [self.errorView removeFromSuperview];
  }

  if (self.progressView) {
    [self.progressView removeFromSuperview];
  }

  self.progressView = [[SEAProgressView alloc] initWithFrame:self.view.bounds];
  self.progressView.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.progressView.indeterminate = YES;
  [self.view addSubview:self.progressView];
}

- (void)setUpNoConnectionView {
  [self setUpErrorViewWithText:NSLocalizedString(@"Приложению требуется подключение к интернету.", nil) image:[UIImage imageNamed:@"Globe"]];
}

- (void)setUpLoadingErrorView {
  [self setUpErrorViewWithText:NSLocalizedString(@"Произошла ошибка при загрузке данных. Возможно, что-то не так с вашим подключением или с сервером.", nil) image:[UIImage imageNamed:@"SadFace"] ];
}

- (void)setUpErrorViewWithText:(NSString *)text image:(UIImage *)image {
  if (self.errorView) {
    [self.errorView removeFromSuperview];
  }
  self.errorView = [[SEAErrorView alloc] initWithFrame:self.view.bounds image:image text:text reloadBlock:^{
    [self reload];
  }];
  
  if (self.progressView) {
    [self.view insertSubview:self.errorView belowSubview:self.progressView];
    [self.progressView performFinishAnimation];
  } else {
    [self.view addSubview:self.errorView];
  }
  self.connected = NO;
  self.disconnected = NO;
}

- (void)setUpNavigationBar {
  for (UIViewController *viewController in @[self.moviesViewController, self.showtimesViewController, self.theatresViewController, self.newsViewController, self.settingsViewController]) {
    viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    viewController.navigationController.navigationBar.backIndicatorImage = [[UIImage imageNamed:@"BackIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    viewController.navigationController.navigationBar.backIndicatorTransitionMaskImage = [[UIImage imageNamed:@"BackIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    viewController.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    viewController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
  }

  for (UIViewController *viewController in @[self.moviesViewController, self.showtimesViewController, self.theatresViewController]) {
    UIButton *dateFilterButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [dateFilterButton setBackgroundImage:[[UIImage imageNamed:@"CalendarIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [dateFilterButton addTarget:self action:@selector(openDateFilterView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *dateFilterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:dateFilterButton];
    dateFilterButtonItem.enabled = NO;
    viewController.navigationItem.rightBarButtonItem = dateFilterButtonItem;
    [viewController.navigationItem startAnimating];
  }
}

- (void)setUpLocationSelector {
  NSArray *cities = [[SEADataManager sharedInstance] allCities];
  NSUInteger selectedIndex = [SEALocationManager sharedInstance].currentCity ? [cities indexOfObject : [SEALocationManager sharedInstance].currentCity] : NSNotFound;

  if (selectedIndex == NSNotFound) {
    selectedIndex = 0;
  }

  NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:cities.count];
  for (NSString *city in cities) {
    AYSlidingPickerViewItem *item = [[AYSlidingPickerViewItem alloc] initWithTitle:city handler:^(BOOL finished) {
      [SEALocationManager sharedInstance].currentCity = city;
      DDLogInfo(@"Switched city to %@", city);
      [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:city forKey:kCityNameKey];
      for (UIViewController *viewController in @[self.moviesViewController, self.showtimesViewController, self.theatresViewController]) {
        SEANavigationBarTitleView *titleView = [SEANavigationBarTitleView new];
        titleView.city = city;
        titleView.dateIndex = [SEADataManager sharedInstance].selectedDayIndex;
        viewController.navigationItem.titleView = titleView;
      }
      [self refreshNowPlayingMovies];
      [self refreshTheatres];
    }];
    [items addObject:item];
  }

  self.locationPickerView = [AYSlidingPickerView sharedInstance];
  self.locationPickerView.backgroundColor = [UIColor colorWithHexString:kAmberColor];
  self.locationPickerView.itemColor = [UIColor colorWithHexString:kOnyxColor];
  self.locationPickerView.itemFont = [UIFont regularFontWithSize:[UIFont locationPickerViewItemFontSize]];
  self.locationPickerView.mainView = self.view;
  self.locationPickerView.items = items;
  self.locationPickerView.selectedIndex = selectedIndex;
  
  __weak typeof(self) weakSelf = self;
  self.locationPickerView.willAppearHandler = ^{
    for (UIViewController *viewController in @[weakSelf.moviesViewController, weakSelf.showtimesViewController, weakSelf.theatresViewController]) {
      UIView *titleView = viewController.navigationItem.titleView;
      if ([titleView isKindOfClass:[SEANavigationBarTitleView class]]) {
        [(SEANavigationBarTitleView *)titleView pointArrowUp];
      }
    }
  };
  self.locationPickerView.willDismissHandler = ^{
    for (UIViewController *viewController in @[weakSelf.moviesViewController, weakSelf.showtimesViewController, weakSelf.theatresViewController]) {
      UIView *titleView = viewController.navigationItem.titleView;
      if ([titleView isKindOfClass:[SEANavigationBarTitleView class]]) {
        [(SEANavigationBarTitleView *)titleView pointArrowDown];
      }
    }
  };
}

- (void)setUpDateFilterView {
  self.dateFilterView = [[LGFilterView alloc] initWithTitles:@[NSLocalizedString(@"Сегодня", nil), NSLocalizedString(@"Завтра", nil)] actionHandler:^(LGFilterView *dateFilterView, NSString *title, NSUInteger index) {
    [SEADataManager sharedInstance].selectedDayIndex = index;
    DDLogInfo(@"Filtered movies to %@", index == SEAShowtimesDateToday ? @"today" : @"tomorrow");
    for (UIViewController *viewController in @[self.moviesViewController, self.showtimesViewController, self.theatresViewController]) {
      SEANavigationBarTitleView *titleView = [SEANavigationBarTitleView new];
      titleView.city = [[SEADataManager sharedInstance] citySupported] ? [SEALocationManager sharedInstance].currentCity : NSLocalizedString(@"Выберите город", nil);
      titleView.dateIndex = index;
      viewController.navigationItem.titleView = titleView;
    }
    [self refreshNowPlayingMovies];
    [self refreshTheatres];
  } cancelHandler:nil];
  self.dateFilterView.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.dateFilterView.separatorsVisible = NO;
  self.dateFilterView.contentInset = UIEdgeInsetsMake(44 + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame), 0, 0, 0);
  self.dateFilterView.selectedIndex = 0;
  self.dateFilterView.transitionStyle = LGFilterViewTransitionStyleTop;
  self.dateFilterView.numberOfLines = 0;
  self.dateFilterView.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.dateFilterView.titleColor = self.dateFilterView.titleColorHighlighted = [UIColor whiteColor];
  self.dateFilterView.titleColorSelected = [UIColor colorWithHexString:kOnyxColor];
  self.dateFilterView.backgroundColorHighlighted = [UIColor colorWithWhite:0 alpha:0.5f];
  self.dateFilterView.backgroundColorSelected = [UIColor colorWithHexString:kAmberColor];
  
  for (UIViewController *viewController in @[self.moviesViewController, self.showtimesViewController, self.theatresViewController]) {
    viewController.navigationItem.rightBarButtonItem.enabled = YES;
  }
}

- (void)openDateFilterView {
  if (self.dateFilterView.isShowing) {
    [self.dateFilterView dismissAnimated:YES completionHandler:nil];
  } else {
    [self.dateFilterView showInView:[self currentViewController].view animated:YES completionHandler:nil];
  }
}

- (void)setUpPromptView {
  if (!self.promptView) {
    CGFloat cacheSize = [[SDImageCache sharedImageCache] getSize] / 1024.f / 1024.f;
    if (![SEAPromptView hasHadInteractionForCurrentVersion] && cacheSize > 5) {
      self.promptView = [[SEAPromptView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
      self.promptView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      self.promptView.delegate = self;
      self.promptView.backgroundColor = [UIColor colorWithHexString:kAmberColor];
      [self.view addSubview:self.promptView];
      [self slideInFromBottom:self.promptView];
    }
  }
}

- (UIViewController *)currentViewController {
  switch (self.selectedIndex) {
    case 0:
      return self.moviesViewController;
    case 1:
      return self.showtimesViewController;
    case 2:
      return self.theatresViewController;
    case 3:
      return self.newsViewController;
    case 4:
      return self.settingsViewController;
    default:
      return nil;
  }
}

#pragma mark SEAPromptViewDelegate

- (void)promptForReview {
  [self slideOutToBottom:self.promptView completion:^(BOOL completed) {
    [self.promptView removeFromSuperview];
    [AYAppStore openAppStoreReviewForApp:kAppId];
  }];
}

- (void)promptForFeedback {
  [self slideOutToBottom:self.promptView completion:^(BOOL completed) {
    [self.promptView removeFromSuperview];
    if ([MFMailComposeViewController canSendMail]) {
      AYFeedback *feedback = [AYFeedback new];
      self.mailComposeViewController = [MFMailComposeViewController new];
      self.mailComposeViewController.mailComposeDelegate = self;
      self.mailComposeViewController.toRecipients = @[@"ayan.yenb@gmail.com"];
      self.mailComposeViewController.subject = feedback.subject;
      [self.mailComposeViewController setMessageBody:feedback.messageWithMetaData isHTML:NO];
      [self presentViewController:self.mailComposeViewController animated:YES completion:^{
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:25.0f / 255.0f green:125.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f]];
      }];
    } else {
      SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:NSLocalizedString(@"Настройте ваш почтовый сервис", nil) body:NSLocalizedString(@"Чтобы отправить нам письмо, вам необходим настроенный почтовый аккаунт.", nil)];
      [alertView show];
    }
  }];
}

- (void)promptClose {
  [self slideOutToBottom:self.promptView completion:^(BOOL completed) {
    [self.promptView removeFromSuperview];
  }];
}

- (void)slideInFromBottom:(UIView *)view {
  [UIView animateWithDuration:0.3 animations:^{
    view.top -= view.height;
  } completion:nil];
}

- (void)slideOutToBottom:(UIView *)view completion:(void (^)(BOOL completed))completion {
  [UIView animateWithDuration:0.3 animations:^{
    view.top += view.height;
  } completion:completion];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
  [self dismissViewControllerAnimated:YES completion:^{
    if (result == MFMailComposeResultSent) {
      SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:NSLocalizedString(@"Спасибо!", nil) body:NSLocalizedString(@"Ваш отзыв был получен, и мы скоро с вами свяжемся.", nil)];
      [alertView show];
    }
  }];
}

@end
