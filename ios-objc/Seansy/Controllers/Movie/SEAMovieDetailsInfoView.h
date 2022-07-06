#import "SEAMovie.h"

@protocol SEAMovieDetailsInfoViewDelegate <NSObject>
@required
- (CGFloat)topHeight;
- (void)presentViewController:(UIViewController *)viewControllerToPresent;
@end

@interface SEAMovieDetailsInfoView : UIView

#pragma mark Properties

@property (nonatomic, getter = isExpanded) BOOL expanded;
@property (nonatomic) CGFloat fullHeight;
@property (nonatomic) CGFloat summaryHeight;
@property (nonatomic) UIImageView *poster;
@property (weak, nonatomic) id<SEAMovieDetailsInfoViewDelegate> delegate;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame movie:(SEAMovie *)movie;
- (void)updateLabelColors:(NSDictionary *)colors;
- (void)expand:(BOOL)revert;

@end
