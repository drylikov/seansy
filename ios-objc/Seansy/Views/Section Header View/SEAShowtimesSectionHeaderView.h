#import "SEAArrowIcon.h"
#import "SEAMovie.h"
#import "SEATheatre.h"
#import "SEAPagerViewController.h"

@class SEAShowtimesSectionHeaderView;

@protocol SEAShowtimesSectionHeaderViewDelegate <NSObject>
@required
- (void)sectionHeaderViewBackdropTapped:(SEAShowtimesSectionHeaderView *)headerView;
@optional
- (void)sectionHeaderViewPosterTapped:(SEAShowtimesSectionHeaderView *)headerView;
- (void)sectionHeaderViewStarred:(SEAShowtimesSectionHeaderView *)headerView;
@end

@interface SEAShowtimesSectionHeaderView : UITableViewHeaderFooterView <SEAPosterViewDelegate>

#pragma mark Properties

@property (nonatomic) SEAArrowIcon *arrowIcon;
@property (nonatomic) UIImageView *backdrop;
@property (nonatomic) UIImageView *poster;
@property (nonatomic) UILabel *subtitle;
@property (nonatomic) UILabel *title;
@property (weak, nonatomic) id<SEAShowtimesSectionHeaderViewDelegate> delegate;
@property (weak, nonatomic) SEAMovie *movie;
@property (weak, nonatomic) SEATheatre *theatre;

#pragma mark Methods

- (void)startFloatAnimation;
- (void)stopFloatAnimation;
- (void)setUpArrowIconWithOrientation:(SEAArrowIconOrientation)orientation;

@end
