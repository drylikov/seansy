@interface UIFont (SEASizes)

+ (CGFloat)smallTextFontSize;
+ (CGFloat)mediumTextFontSize;
+ (CGFloat)largeTextFontSize;
+ (CGFloat)movieTitleFontSize;
+ (CGFloat)theatreNameFontSize;
+ (CGFloat)carouselTitleFontSize;
+ (CGFloat)personsCarouselPlaceholderFontSize;
+ (CGFloat)ratingFontSize;
+ (CGFloat)locationPickerViewItemFontSize;
+ (CGFloat)actionSheetTitleFontSize;
+ (CGFloat)actionSheetButtonFontSize;
+ (CGFloat)alertViewTitleFontSize;
+ (CGFloat)alertViewButtonFontSize;
+ (CGFloat)showtimeTitleFontSize;
+ (CGFloat)showtimeFormatFontSize;
+ (CGFloat)featuredMovieTitleFontSize;
+ (CGFloat)walkthroughTitleFontSize;
+ (CGFloat)navigationBarFontSize;
+ (CGFloat)tabBarFontSize;
+ (CGFloat)movieSectionHeaderFontSize;
+ (CGFloat)theatreSectionHeaderFontSize;
+ (CGFloat)newsEntryTitleFontSize;

+ (instancetype)regularFontWithSize:(CGFloat)size;
+ (instancetype)lightFontWithSize:(CGFloat)size;
+ (instancetype)italicFontWithSize:(CGFloat)size;
+ (instancetype)boldFontWithSize:(CGFloat)size;
+ (instancetype)timeFontWithSize:(CGFloat)size;

@end
