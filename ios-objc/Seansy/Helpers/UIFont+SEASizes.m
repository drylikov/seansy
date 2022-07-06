#import "UIFont+SEASizes.h"

#import "AYMacros.h"

static NSString *const kLightFontName = @"Lato-Light";
static NSString *const kRegularFontName = @"Lato-Regular";
static NSString *const kItalicFontName = @"Lato-Italic";
static NSString *const kBoldFontName = @"Lato-Semibold";
static NSString *const kTimeFontName = @"StreetSemiBold";

@implementation UIFont (SEASizes)

+ (CGFloat)smallTextFontSize {
  if (IS_IPHONE_6P) {
    return 16;
  } else if (IS_IPHONE_6) {
    return 15;
  } else {
    return 14;
  }
}

+ (CGFloat)mediumTextFontSize {
  if (IS_IPHONE_6P) {
    return 18;
  } else if (IS_IPHONE_6) {
    return 17;
  } else {
    return 16;
  }
}

+ (CGFloat)largeTextFontSize {
  if (IS_IPHONE_6P) {
    return 20;
  } else if (IS_IPHONE_6) {
    return 19;
  } else {
    return 18;
  }
}

+ (CGFloat)movieTitleFontSize {
  if (IS_IPHONE_6P) {
    return 46;
  } else if (IS_IPHONE_6) {
    return 42;
  } else {
    return 40;
  }
}

+ (CGFloat)theatreNameFontSize {
  if (IS_IPHONE_6P) {
    return 30;
  } else if (IS_IPHONE_6) {
    return 28;
  } else {
    return 26;
  }
}

+ (CGFloat)carouselTitleFontSize {
  if (IS_IPHONE_6P) {
    return 24;
  } else if (IS_IPHONE_6) {
    return 22;
  } else {
    return 20;
  }
}

+ (CGFloat)personsCarouselPlaceholderFontSize {
  if (IS_IPHONE_6P) {
    return 46;
  } else if (IS_IPHONE_6) {
    return 42;
  } else {
    return 40;
  }
}

+ (CGFloat)ratingFontSize {
  if (IS_IPHONE_6P) {
    return 22;
  } else if (IS_IPHONE_6) {
    return 20;
  } else {
    return 18;
  }
}

+ (CGFloat)locationPickerViewItemFontSize {
  if (IS_IPHONE_6P) {
    return 22;
  } else if (IS_IPHONE_6) {
    return 21;
  } else {
    return 20;
  }
}

+ (CGFloat)actionSheetTitleFontSize {
  if (IS_IPHONE_6P) {
    return 26;
  } else if (IS_IPHONE_6) {
    return 24;
  } else {
    return 22;
  }
}

+ (CGFloat)actionSheetButtonFontSize {
  if (IS_IPHONE_6P) {
    return 19;
  } else if (IS_IPHONE_6) {
    return 18;
  } else {
    return 17;
  }
}

+ (CGFloat)alertViewTitleFontSize {
  if (IS_IPHONE_6P) {
    return 24;
  } else if (IS_IPHONE_6) {
    return 22;
  } else {
    return 20;
  }
}

+ (CGFloat)alertViewButtonFontSize {
  if (IS_IPHONE_6P) {
    return 21;
  } else if (IS_IPHONE_6) {
    return 20;
  } else {
    return 19;
  }
}

+ (CGFloat)showtimeTitleFontSize {
  if (IS_IPHONE_6P) {
    return 40;
  } else if (IS_IPHONE_6) {
    return 37;
  } else if (IS_IPHONE_5) {
    return 34;
  } else {
    return 26;
  }
}

+ (CGFloat)showtimeFormatFontSize {
  if (IS_IPHONE_6P) {
    return 36;
  } else if (IS_IPHONE_6) {
    return 33;
  } else if (IS_IPHONE_5) {
    return 30;
  } else {
    return 24;
  }
}

+ (CGFloat)featuredMovieTitleFontSize {
  if (IS_IPHONE_6P) {
    return 34;
  } else if (IS_IPHONE_6) {
    return 32;
  } else {
    return 30;
  }
}

+ (CGFloat)walkthroughTitleFontSize {
  if (IS_IPHONE_6P) {
    return 28;
  } else if (IS_IPHONE_6) {
    return 26;
  } else {
    return 24;
  }
}

+ (CGFloat)navigationBarFontSize {
  return 17;
}

+ (CGFloat)tabBarFontSize {
  return 11;
}

+ (CGFloat)movieSectionHeaderFontSize {
  return 26;
}

+ (CGFloat)theatreSectionHeaderFontSize {
  return 20;
}

+ (CGFloat)newsEntryTitleFontSize {
  return 24;
}

+ (instancetype)regularFontWithSize:(CGFloat)size {
  return [UIFont fontWithName:kRegularFontName size:size];
}

+ (instancetype)lightFontWithSize:(CGFloat)size {
  return [UIFont fontWithName:kLightFontName size:size];
}

+ (instancetype)italicFontWithSize:(CGFloat)size {
  return [UIFont fontWithName:kItalicFontName size:size];
}

+ (instancetype)boldFontWithSize:(CGFloat)size {
  return [UIFont fontWithName:kBoldFontName size:size];
}

+ (instancetype)timeFontWithSize:(CGFloat)size {
  return [UIFont fontWithName:kTimeFontName size:size];
}

@end
