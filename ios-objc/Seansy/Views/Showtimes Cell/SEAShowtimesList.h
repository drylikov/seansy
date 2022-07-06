#import "SEAMovie.h"
#import "SEAPagerViewController.h"
#import "SEAShowtimesCell.h"

@class SEAShowtimesList;

@protocol SEAShowtimesListDelegate <NSObject>
@required
- (void)cellPosterTapped:(SEAShowtimesList *)cell;
@end

@interface SEAShowtimesList : SEAShowtimesCell <SEAPosterViewDelegate>

@property (nonatomic) UIImageView *backdrop;
@property (nonatomic) UIImageView *poster;
@property (weak, nonatomic) id<SEAShowtimesListDelegate> delegate;
@property (weak, nonatomic) SEAMovie *movie;

@end
