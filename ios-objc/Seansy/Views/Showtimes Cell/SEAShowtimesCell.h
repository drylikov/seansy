#import "SEAShowtime.h"
#import "SEAShowtimesItemCell.h"
#import <AMPopTip/AMPopTip.h>

extern UIEdgeInsets const kShowtimesCellCollectionViewPadding;

@protocol SEAShowtimesCellDelegate <NSObject>
@required
- (AMPopTip *)visiblePopTip;
- (SEAShowtimesItemCell *)cellForVisiblePopTip;
- (void)hideVisiblePopTip;
- (void)openShowtime:(SEAShowtime *)showtime;
- (void)buyTicketForShowtime:(SEAShowtime *)showtime;
- (void)setVisiblePopTip:(AMPopTip *)visiblePopTip;
@end

@interface SEAShowtimesCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

#pragma mark Properties

@property (nonatomic) AMPopTip *popTip;
@property (nonatomic) NSArray *showtimes;
@property (nonatomic) NSMutableArray *cells;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIColor *color;
@property (weak, nonatomic) id<SEAShowtimesCellDelegate> popTipDelegate;
@property (weak, nonatomic) SEAShowtimesItemCell *activeCell;
@property (weak, nonatomic) UIScrollView *containerView;

#pragma mark Methods

- (BOOL)hasPoptip:(AMPopTip *)popTip;
- (void)refresh;

@end
