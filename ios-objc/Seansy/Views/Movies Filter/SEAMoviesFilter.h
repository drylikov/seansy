@interface SEAMoviesFilter : NSObject

#pragma mark Properties

@property (nonatomic) NSInteger ratingFilter;
@property (nonatomic) NSInteger runtimeFilter;
@property (nonatomic) NSMutableArray *genresFilter;
@property (nonatomic) BOOL childrenFilter;

#pragma mark Methods

+ (SEAMoviesFilter *)sharedInstance;
- (UIView *)ratingSlider;
- (UIView *)runtimeSlider;
- (UIView *)childrenSwitch;
- (UIView *)genresSelector;

@end
