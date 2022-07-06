@interface SEABackdrop : NSObject <NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) UIImage *originalImage;
@property (nonatomic, readonly) UIImage *filteredImage;
@property (nonatomic, readonly) NSMutableDictionary *colors;
@property (nonatomic, readonly) BOOL colorsExtracted;

#pragma mark Methods

- (instancetype)initWithUrl:(NSURL *)url;
- (void)getOriginalImageWithProgressBlock:(void (^)(CGFloat progress))progressBlock completionBlock:(void (^)(UIImage *originalImage, BOOL fromCache))completionBlock;
- (void)getFilteredImageWithProgressBlock:(void (^)(CGFloat progress))progressBlock completionBlock:(void (^)(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache))completionBlock;
- (void)getColorsWithCompletionBlock:(void (^)(NSDictionary *colors))completionBlock;

@end
