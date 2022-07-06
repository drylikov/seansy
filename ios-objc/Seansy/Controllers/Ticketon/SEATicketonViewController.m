#import "SEATicketonViewController.h"

@implementation SEATicketonViewController

- (instancetype)initWithShowtime:(SEAShowtime *)showtime {
  self = [super initWithURL:[showtime ticketonUrl]];
  if (!self) {
    return nil;
  }
  [UINavigationBar appearanceWhenContainedIn:[SEATicketonViewController class], nil].barStyle = UIBarStyleBlack;
  [UIToolbar appearanceWhenContainedIn:[SEATicketonViewController class], nil].barStyle = UIBarStyleBlack;
  [UIBarButtonItem appearanceWhenContainedIn:[SEATicketonViewController class], nil].tintColor = [UIColor whiteColor];

  return self;
}

@end
