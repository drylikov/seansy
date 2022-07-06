#import "SEATabBarItemViewControllerDelegate.h"
#import "SEAErrorView.h"

@interface SEATableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, SEATabBarItemViewControllerDelegate>

@property (nonatomic, getter = shouldHideTabBar) BOOL hideTabBar;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) SEAErrorView *errorView;

@end
