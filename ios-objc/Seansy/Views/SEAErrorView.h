typedef void (^SEAErrorViewReloadBlock)(void);

@interface SEAErrorView : UIView

#pragma mark Properties

@property (copy, nonatomic) NSString *text;
@property (nonatomic) CGFloat verticalOffset;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text;
- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text reloadBlock:(SEAErrorViewReloadBlock)reloadBlock;

@end
