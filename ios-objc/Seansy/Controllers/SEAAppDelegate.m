#import "SEAAppDelegate.h"

#import "SEAAppCoordinator.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "Secrets.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import <Analytics/Analytics.h>
#import <Crashlytics/Crashlytics.h>
#import <EUMTouchPointView/EUMShowTouchWindow.h>
#import <Fabric/Fabric.h>
#import <YandexMobileMetrica/YandexMobileMetrica.h>

#define SHOW_TOUCHES 0

@interface SEAAppDelegate ()

@property (nonatomic) SEAAppCoordinator *appCoordinator;

@end

@implementation SEAAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set up logger
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  // Set up analytics
  [Fabric with:@[CrashlyticsKit]];
  [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:kSegmentWriteKey]];
  [YMMYandexMetrica activateWithApiKey:kYandexMetricaApiKey];

  // Set default user preferences
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] registerDefaults:@{
     kMoviesSortByKey : @(SEAMoviesSortByPopularity),
     kTheatresSortByKey : @(SEATheatresSortByDistance),
     kShowPercentRatingsKey : @NO,
     kSaveFiltersKey : @NO,
     kParallaxKey : @YES
   }];

#if SHOW_TOUCHES
  self.window = [[EUMShowTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [(EUMShowTouchWindow *)self.window setPointerColor:[UIColor colorWithHexString:kAmberColor]];
#else
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
#endif

  self.navigationController = [UINavigationController new];
  self.window.rootViewController = self.navigationController;
  self.appCoordinator = [[SEAAppCoordinator alloc] initWithNavigationController:self.navigationController];
  [self.appCoordinator start];

  self.orientationMask = UIInterfaceOrientationMaskPortrait;
  [application setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
  [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
  [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
  [self setUpAppearances];
  [self.window makeKeyAndVisible];

  return YES;
}

- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration {
  [[UIApplication sharedApplication] setStatusBarHidden:UIInterfaceOrientationIsLandscape(newStatusBarOrientation) withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [self.appCoordinator handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [self.appCoordinator restore];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
  return self.orientationMask;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
  return [self.appCoordinator handleUserActivity:userActivity];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  RACSignal *dataSignal = [[[SEADataManager sharedInstance] loadDataFromCache:NO] catch:^RACSignal *(NSError *error) {
    return [[[RACSignal empty] delay:5] concat:[RACSignal error:error]];
  }];
  RACSignal *locationSignal = [[SEALocationManager sharedInstance] getCurrentCity];
  [[[[[RACSignal merge:@[locationSignal, dataSignal]] deliverOn:RACScheduler.mainThreadScheduler] retry:3] then:^RACSignal *{
    return [[SEADataManager sharedInstance] setUpSpotlightSearch];
  }] subscribeError:^(NSError *error) {
    completionHandler(UIBackgroundFetchResultFailed);
  } completed:^{
    completionHandler(UIBackgroundFetchResultNewData);
  }];
}

#pragma mark Private

- (void)setUpAppearances {
  [[UIBarButtonItem appearance] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont navigationBarFontSize]] } forState:UIControlStateNormal];
  [[UINavigationBar appearance] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont navigationBarFontSize]] }];
  [[UITabBar appearance] setTintColor:[UIColor colorWithHexString:kAmberColor]];
  [[UISwitch appearance] setTintColor:[UIColor colorWithHexString:kAmberColor]];
  [[UISwitch appearance] setOnTintColor:[UIColor colorWithHexString:kAmberColor]];
  [[UITabBarItem appearance] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont tabBarFontSize]] } forState:UIControlStateNormal];
}

#pragma mark Public

- (void)blockOrientation {
  self.orientationMask = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight : UIInterfaceOrientationMaskPortrait;
}

- (void)restoreOrientation {
  self.orientationMask = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

@end
