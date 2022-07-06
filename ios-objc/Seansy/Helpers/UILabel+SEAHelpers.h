@interface UILabel (SEAHelpers)

- (void)adjustFontSizeWithMaxLines:(NSUInteger)maxLines fontFloor:(CGFloat)fontFloor;
- (void)setFrameToFitWithHeightLimit:(CGFloat)heightLimit;
- (CGSize)sizeToFitWithHeightLimit:(CGFloat)heightLimit;

@end
