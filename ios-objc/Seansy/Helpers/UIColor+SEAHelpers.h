@interface UIColor (SEAHelpers)

+ (instancetype)colorWithHexString:(NSString *)stringToConvert;
- (instancetype)lighterColor:(CGFloat)increment;
- (instancetype)darkerColor:(CGFloat)decrement;
- (BOOL)isEqualToColor:(UIColor *)compareColor;
- (BOOL)isDarkColor;
- (BOOL)isDistinct:(UIColor *)compareColor;
- (UIColor *)colorWithMinimumSaturation:(CGFloat)minSaturation;
- (BOOL)isBlackOrWhite;
- (BOOL)isBlack;
- (BOOL)isContrastingColor:(UIColor *)color;
- (instancetype)inversedColor;
- (instancetype)blendWithColor:(UIColor *)color2 alpha:(CGFloat)alpha2;

@end
