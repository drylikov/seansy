#import "SEAConstants.h"
#import "SEAMoviesGridCell.h"
#import "SEAPagerChildItemViewController.h"

@interface SEAMoviesPagerChildItemViewController : SEAPagerChildItemViewController <UICollectionViewDelegate, UICollectionViewDataSource>

#pragma mark Properties

@property (nonatomic) SEAMoviesType type;
@property (nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic) SEAMoviesGridCell *selectedCell;

#pragma mark Methods

- (instancetype)initWithType:(SEAMoviesType)type;
- (CGRect)selectedCellFrame;
- (void)openMovie:(SEAMovie *)movie;

@end
