#import "SEAMovie.h"
#import "SEAShowtimesCarousel.h"
#import "SEAShowtimesSectionHeaderView.h"
#import <AMPopTip/AMPopTip.h>

@protocol SEAMovieShowtimesViewDelegate <NSObject>
- (UINavigationController *)navigationController;
@end

@interface SEAMovieShowtimesView : UIView <UITableViewDataSource, UITableViewDelegate, SEAShowtimesSectionHeaderViewDelegate, SEAShowtimesCellDelegate>

#pragma mark Properties

@property (nonatomic) UITableView *tableView;
@property (weak, nonatomic) id<SEAMovieShowtimesViewDelegate> delegate;
@property (weak, nonatomic) UIScrollView *containerView;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame movie:(SEAMovie *)movie;
- (void)refresh;
- (void)hideVisiblePopTip;

@end
