#import "UIColor+SEAHelpers.h"

@implementation UIColor (SEAHelpers)

+ (instancetype)colorWithHexString:(NSString *)stringToConvert {
  NSString *string = stringToConvert;

  if ([string hasPrefix:@"#"]) {
    string = [string substringFromIndex:1];
  }

  NSScanner *scanner = [NSScanner scannerWithString:string];
  unsigned hexNum;
  if (![scanner scanHexInt:&hexNum]) {
    return nil;
  }
  int r = (hexNum >> 16) & 0xFF;
  int g = (hexNum >> 8) & 0xFF;
  int b = (hexNum) & 0xFF;

  return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:1.0f];
}

- (instancetype)lighterColor:(CGFloat)increment {
  CGFloat r, g, b, a;

  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return [UIColor colorWithRed:(CGFloat)MIN(r + increment, 1)
            green:(CGFloat)MIN(g + increment, 1)
            blue:(CGFloat)MIN(b + increment, 1)
            alpha:a];
  }
  return nil;
}

- (instancetype)darkerColor:(CGFloat)decrement {
  CGFloat r, g, b, a;

  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return [UIColor colorWithRed:(CGFloat)MAX(r - decrement, 0)
            green:(CGFloat)MAX(g - decrement, 0)
            blue:(CGFloat)MAX(b - decrement, 0)
            alpha:a];
  }
  return nil;
}

- (BOOL)isEqualToColor:(UIColor *)compareColor {
  CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();

  UIColor *(^convertColorToRGBSpace)(UIColor *) = ^(UIColor *color) {
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
      const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
      CGFloat components[4] = {
        oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]
      };
      CGColorRef colorRef = CGColorCreate(colorSpaceRGB, components);

      UIColor *convertedColor = [UIColor colorWithCGColor:colorRef];
      CGColorRelease(colorRef);
      return convertedColor;
    } else {
      return color;
    }
  };

  UIColor *selfColor = convertColorToRGBSpace(self);

  compareColor = convertColorToRGBSpace(compareColor);
  CGColorSpaceRelease(colorSpaceRGB);

  return [selfColor isEqual:compareColor];
}

- (BOOL)isDarkColor {
  CGFloat r, g, b, a;

  [self getRed:&r green:&g blue:&b alpha:&a];
  CGFloat lum = 0.2126f * r + 0.7152f * g + 0.0722f * b;
  if (lum < .5f) {
    return YES;
  }
  return NO;
}

- (BOOL)isDistinct:(UIColor *)compareColor {
  CGFloat r, g, b, a;
  CGFloat r1, g1, b1, a1;

  [self getRed:&r green:&g blue:&b alpha:&a];
  [compareColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  CGFloat threshold = .25;   //.15
  if (fabs(r - r1) > threshold ||
      fabs(g - g1) > threshold ||
      fabs(b - b1) > threshold ||
      fabs(a - a1) > threshold) {
    // Check for grays, prevent multiple gray colors
    if (fabs(r - g) < .03 && fabs(r - b) < .03) {
      if (fabs(r1 - g1) < .03 && fabs(r1 - b1) < .03) {
        return NO;
      }
    }
    return YES;
  }
  return NO;
}

- (instancetype)colorWithMinimumSaturation:(CGFloat)minSaturation {
  CGFloat hue = 0.0;
  CGFloat saturation = 0.0;
  CGFloat brightness = 0.0;
  CGFloat alpha = 0.0;

  [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
  if (saturation < minSaturation) {
    return [UIColor colorWithHue:hue saturation:minSaturation brightness:brightness alpha:alpha];
  }
  return self;
}

- (BOOL)isBlackOrWhite {
  CGFloat r, g, b, a;

  [self getRed:&r green:&g blue:&b alpha:&a];
  if (r > .91 && g > .91 && b > .91) {
    return YES;     // White
  }
  if (r < .09 && g < .09 && b < .09) {
    return YES;     // Black
  }
  return NO;
}

- (BOOL)isBlack {
  CGFloat r, g, b, a;

  [self getRed:&r green:&g blue:&b alpha:&a];
  if (r < .01 && g < .01 && b < .01) {
    return YES;
  }
  return NO;
}

- (BOOL)isContrastingColor:(UIColor *)color {
  if (color != nil) {
    CGFloat br, bg, bb, ba;
    CGFloat fr, fg, fb, fa;
    [self getRed:&br green:&bg blue:&bb alpha:&ba];
    [color getRed:&fr green:&fg blue:&fb alpha:&fa];
    CGFloat bLum = 0.2126f * br + 0.7152f * bg + 0.0722f * bb;
    CGFloat fLum = 0.2126f * fr + 0.7152f * fg + 0.0722f * fb;
    CGFloat contrast = 0.;
    if (bLum > fLum) {
      contrast = (bLum + 0.05f) / (fLum + 0.05f);
    } else {
      contrast = (fLum + 0.05f) / (bLum + 0.05f);
    }
    // Return contrast > 3.0; //3-4.5 W3C recommends a minimum ratio of 3:1
    return contrast > 3;
  }
  return YES;
}

- (instancetype)inversedColor {
  CGFloat r, g, b, a;

  [self getRed:&r green:&g blue:&b alpha:&a];
  return [UIColor colorWithRed:1 - r green:1 - g blue:1 - b alpha:a];
}

- (instancetype)blendWithColor:(UIColor *)color2 alpha:(CGFloat)alpha2 {
  alpha2 = MIN(1, MAX(0, alpha2) );
  CGFloat beta = 1 - alpha2;
  CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
  [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
  CGFloat red = r1 * beta + r2 * alpha2;
  CGFloat green = g1 * beta + g2 * alpha2;
  CGFloat blue = b1 * beta + b2 * alpha2;
  CGFloat alpha = a1 * beta + a2 * alpha2;
  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
