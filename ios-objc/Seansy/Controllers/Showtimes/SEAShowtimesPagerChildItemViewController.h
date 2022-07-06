#import "SEAConstants.h"
#import "SEAMoviesFilter.h"
#import "SEAPagerChildItemViewController.h"
#import "SEAShowtimesCarouselWithLabel.h"
#import "SEAShowtimesList.h"
#import "SEAShowtimesSectionHeaderView.h"
#import <AMPopTip/AMPopTip.h>

@interface SEAShowtimesPagerChildItemViewController : SEAPagerChildItemViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SEAShowtimesSectionHeaderViewDelegate, SEAShowtimesCellDelegate, SEAShowtimesListDelegate>

#pragma mark Properties

@property (nonatomic) SEAShowtimesLayout layout;
@property (nonatomic) UITableView *tableView;
@property (weak, nonatomic) AMPopTip *visiblePopTip;
@property (weak, nonatomic) SEAShowtimesList *selectedCell;
@property (weak, nonatomic) SEAShowtimesSectionHeaderView *selectedHeader;

#pragma mark Methods

- (instancetype)initWithLayout:(SEAShowtimesLayout)layout;
- (void)hideVisiblePopTip;

@end
