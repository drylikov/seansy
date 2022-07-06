@interface SEAReviewsCarouselCell : UICollectionViewCell

#pragma mark Properties

@property (nonatomic) NSDictionary *review;

#pragma mark Methods

+ (CGSize)sizeForText:(NSString *)text;

@end
