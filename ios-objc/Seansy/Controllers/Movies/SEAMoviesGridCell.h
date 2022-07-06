#import "SEAMovie.h"
#import "SEAPagerViewController.h"

@interface SEAMoviesGridCell : UICollectionViewCell <SEAPosterViewDelegate>

@property (nonatomic) UIImageView *poster;
@property (weak, nonatomic) SEAMovie *movie;

@end
