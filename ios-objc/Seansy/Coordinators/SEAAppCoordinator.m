#import "SEAAppCoordinator.h"

#import "SEAMainTabBarController.h"
#import "SEAWalkthroughViewController.h"
#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "SEATabBarItemViewControllerDelegate.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SimulatorStatusMagic/SDStatusBarManager.h>

@interface SEAAppCoordinator ()

@property (nonatomic) UINavigationController *navigationController;

@end

@implementation SEAAppCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.navigationController = navigationController;
  self.navigationController.navigationBarHidden = YES;

  return self;
}

- (void)start {
#ifdef SNAPSHOT
  [self.navigationController pushViewController:[SEAMainTabBarController sharedInstance] animated:NO];
  NSDateFormatter *formatter = [NSDateFormatter new];
  [formatter setDateFormat:@"HH:mm"];
  [SDStatusBarManager sharedInstance].timeString = [formatter stringFromDate:[NSDate date]];
  [[SDStatusBarManager sharedInstance] enableOverrides];
#else
  // Show the onboarding tutorial if app opened for the first time
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kSeenWalkthroughKey] && ![SEAWalkthroughViewController hasUnseenNewFeatures]) {
    [self.navigationController pushViewController:[SEAMainTabBarController sharedInstance] animated:NO];
  } else {
    __weak typeof(self) weakSelf = self;
    SEAWalkthroughViewController *walkthroughViewController = [[SEAWalkthroughViewController alloc] initWithCompletionHandler:^{
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSeenWalkthroughKey];
      [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
      [weakSelf.navigationController pushViewController:[SEAMainTabBarController sharedInstance] animated:NO];
    }];
    [self.navigationController pushViewController:walkthroughViewController animated:NO];
  }
#endif
}

- (void)restore {
  if ([SEAMainTabBarController sharedInstance].selectedIndex > 3) {
    return;
  }
  id<SEATabBarItemViewControllerDelegate> selectedViewController = [(UINavigationController *)[SEAMainTabBarController sharedInstance].selectedViewController viewControllers][0];
  [selectedViewController restoreBars];
}

- (BOOL)handleUserActivity:(NSUserActivity *)userActivity {
  if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
    NSString *identifierPath = [NSString stringWithFormat:@"%@", [userActivity.userInfo objectForKey:CSSearchableItemActivityIdentifier]];
    if (identifierPath) {
      NSInteger movieId = [[identifierPath componentsSeparatedByString:@"-"][1] integerValue];
      DDLogInfo(@"Opening movie id: %@", @(movieId));
      [[SEAMainTabBarController sharedInstance] openMovieWithId:movieId];
      return YES;
    }
  }
  return NO;
}

- (BOOL)handleOpenURL:(NSURL *)url {
  NSString *path = [url.absoluteString stringByReplacingOccurrencesOfString:url.scheme withString:@""];
  if ([path containsString:@"movie"]) {
    NSInteger movieId = [[path componentsSeparatedByString:@"-"][1] integerValue];
    DDLogInfo(@"Opening movie id: %@", @(movieId));
    [[SEAMainTabBarController sharedInstance] openMovieWithId:movieId];
    return YES;
  }
  return NO;
}

@end
