#import "SEAMovie.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SEAFeaturedMovieView : UIView

#pragma mark Properties

@property (nonatomic, getter = shouldUsePercents) BOOL usePercents;

#pragma mark Methods

- (RACSignal *)updateMovie:(SEAMovie *)movie;

@end
