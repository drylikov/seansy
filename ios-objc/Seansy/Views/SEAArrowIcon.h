typedef enum {
  SEAArrowIconOrientationHorizontal,
  SEAArrowIconOrientationVertical
} SEAArrowIconOrientation;

@interface SEAArrowIcon : UIView

#pragma mark Properties

@property (nonatomic) UIColor *color;
@property (nonatomic) SEAArrowIconOrientation orientation;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame orientation:(SEAArrowIconOrientation)orientation;
- (void)pointDownAnimated:(BOOL)animated;
- (void)pointUpAnimated:(BOOL)animated;
- (void)pointRightAnimated:(BOOL)animated;
- (void)pointLeftAnimated:(BOOL)animated;

@end
