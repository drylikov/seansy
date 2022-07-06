#import "SEAMovie.h"

@interface SEAMoviesGridFeaturedMoviesView : UICollectionReusableView

#pragma mark Properties

@property (nonatomic, getter = shouldUsePercents) BOOL usePercents;
@property (nonatomic) NSArray *movies;
@property (nonatomic) SEAMovie *currentMovie;

#pragma mark Methods

- (void)invalidateTimer;

@end
