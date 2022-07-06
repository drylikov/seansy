#import "SEAActivityViewController.h"

@implementation SEAActivityViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
  [(UINavigationController *)viewControllerToPresent navigationBar].barStyle = UIBarStyleBlack;
  [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

@end
