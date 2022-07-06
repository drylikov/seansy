/*
 *   File: UIImage+SEAHelpers.m
 * Abstract: This is a category of UIImage that adds methods to apply blur and tint effects to an image. This is the code you’ll want to look out to find out how to use vImage to efficiently calculate a blur.
 * Version: 1.0
 *
 * Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 * Inc. ("Apple") in consideration of your agreement to the following
 * terms, and your use, installation, modification or redistribution of
 * this Apple software constitutes acceptance of these terms.  If you do
 * not agree with these terms, please do not use, install, modify or
 * redistribute this Apple software.
 *
 * In consideration of your agreement to abide by the following terms, and
 * subject to these terms, Apple grants you a personal, non-exclusive
 * license, under Apple's copyrights in this original Apple software (the
 * "Apple Software"), to use, reproduce, modify and redistribute the Apple
 * Software, with or without modifications, in source and/or binary forms;
 * provided that if you redistribute the Apple Software in its entirety and
 * without modifications, you must retain this notice and the following
 * text and disclaimers in all such redistributions of the Apple Software.
 * Neither the name, trademarks, service marks or logos of Apple Inc. may
 * be used to endorse or promote products derived from the Apple Software
 * without specific prior written permission from Apple.  Except as
 * expressly stated in this notice, no other rights or licenses, express or
 * implied, are granted by Apple herein, including but not limited to any
 * patent rights that may be infringed by your derivative works or by other
 * works in which the Apple Software may be incorporated.
 *
 * The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 * MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 * THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 * OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 *
 * IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 * MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 * AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 * STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (C) 2013 Apple Inc. All Rights Reserved.
 *
 *
 * Copyright © 2013 Apple Inc. All rights reserved.
 * WWDC 2013 License
 *
 * NOTE: This Apple Software was supplied by Apple as part of a WWDC 2013
 * Session. Please refer to the applicable WWDC 2013 Session for further
 * information.
 *
 * IMPORTANT: This Apple software is supplied to you by Apple Inc.
 * ("Apple") in consideration of your agreement to the following terms, and
 * your use, installation, modification or redistribution of this Apple
 * software constitutes acceptance of these terms. If you do not agree with
 * these terms, please do not use, install, modify or redistribute this
 * Apple software.
 *
 * In consideration of your agreement to abide by the following terms, and
 * subject to these terms, Apple grants you a non-exclusive license, under
 * Apple's copyrights in this original Apple software (the "Apple
 * Software"), to use, reproduce, modify and redistribute the Apple
 * Software, with or without modifications, in source and/or binary forms;
 * provided that if you redistribute the Apple Software in its entirety and
 * without modifications, you must retain this notice and the following
 * text and disclaimers in all such redistributions of the Apple Software.
 * Neither the name, trademarks, service marks or logos of Apple Inc. may
 * be used to endorse or promote products derived from the Apple Software
 * without specific prior written permission from Apple. Except as
 * expressly stated in this notice, no other rights or licenses, express or
 * implied, are granted by Apple herein, including but not limited to any
 * patent rights that may be infringed by your derivative works or by other
 * works in which the Apple Software may be incorporated.
 *
 * The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES
 * NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 * IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 * OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 *
 * IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 * MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 * AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 * STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * EA1002
 * 5/3/2013
 */

#import "UIImage+SEAHelpers.h"

#import "UIColor+SEAHelpers.h"
#import "AYMacros.h"

@import Accelerate;
#import <float.h>

@implementation UIImage (SEAHelpers)

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage {
  // Check pre-conditions.
  if (self.size.width < 1 || self.size.height < 1) {
    NSLog(@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
    return nil;
  }
  if (!self.CGImage) {
    NSLog(@"*** error: image must be backed by a CGImage: %@", self);
    return nil;
  }
  if (maskImage && !maskImage.CGImage) {
    NSLog(@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
    return nil;
  }

  CGRect imageRect = {
    CGPointZero, self.size
  };
  UIImage *effectImage = self;

  BOOL hasBlur = blurRadius > __FLT_EPSILON__;
  BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
  if (hasBlur || hasSaturationChange) {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef effectInContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(effectInContext, 1.0, -1.0);
    CGContextTranslateCTM(effectInContext, 0, -self.size.height);
    CGContextDrawImage(effectInContext, imageRect, self.CGImage);

    vImage_Buffer effectInBuffer;
    effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
    effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
    effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
    effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);

    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
    vImage_Buffer effectOutBuffer;
    effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
    effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
    effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
    effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);

    if (hasBlur) {
      // A description of how to compute the box kernel width from the Gaussian
      // radius (aka standard deviation) appears in the SVG spec:
      // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
      //
      // For larger values of 's' (s >= 2.0), an approximation can be used: Three
      // successive box-blurs build a piece-wise quadratic convolution kernel, which
      // approximates the Gaussian kernel to within roughly 3%.
      //
      // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
      //
      // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
      //
      CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
      NSUInteger radius = (NSUInteger)floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
      if (radius % 2 != 1) {
        radius += 1;         // force radius to be odd so that the three box-blur methodology works.
      }
      vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (u_int32_t)radius, (u_int32_t)radius, 0, kvImageEdgeExtend);
      vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (u_int32_t)radius, (u_int32_t)radius, 0, kvImageEdgeExtend);
      vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (u_int32_t)radius, (u_int32_t)radius, 0, kvImageEdgeExtend);
    }
    BOOL effectImageBuffersAreSwapped = NO;
    if (hasSaturationChange) {
      CGFloat s = saturationDeltaFactor;
      CGFloat floatingPointSaturationMatrix[] = {
        0.0722f + 0.9278f * s,  0.0722f - 0.0722f * s,  0.0722f - 0.0722f * s,  0,
        0.7152f - 0.7152f * s,  0.7152f + 0.2848f * s,  0.7152f - 0.7152f * s,  0,
        0.2126f - 0.2126f * s,  0.2126f - 0.2126f * s,  0.2126f + 0.7873f * s,  0,
        0,                    0,                    0,  1,
      };
      const int32_t divisor = 256;
      NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix) / sizeof(floatingPointSaturationMatrix[0]);
      int16_t saturationMatrix[matrixSize];
      for (NSUInteger i = 0; i < matrixSize; ++i) {
        saturationMatrix[i] = (int16_t)roundf((float)(floatingPointSaturationMatrix[i] * divisor));
      }
      if (hasBlur) {
        vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
        effectImageBuffersAreSwapped = YES;
      } else {
        vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
      }
    }
    if (!effectImageBuffersAreSwapped) {
      effectImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    if (effectImageBuffersAreSwapped) {
      effectImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
  }

  // Set up output context.
  UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
  CGContextRef outputContext = UIGraphicsGetCurrentContext();
  CGContextScaleCTM(outputContext, 1.0, -1.0);
  CGContextTranslateCTM(outputContext, 0, -self.size.height);

  // Draw base image.
  CGContextDrawImage(outputContext, imageRect, self.CGImage);

  // Draw effect image.
  if (hasBlur) {
    CGContextSaveGState(outputContext);
    if (maskImage) {
      CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
    }
    CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
    CGContextRestoreGState(outputContext);
  }

  // Add in color tint.
  if (tintColor) {
    CGContextSaveGState(outputContext);
    CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
    CGContextFillRect(outputContext, imageRect);
    CGContextRestoreGState(outputContext);
  }

  // Output image is ready.
  UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return outputImage;
}

#pragma mark -

- (UIImage *)applyBlurToEdges {
  CGImageRef imgRef = self.CGImage;
  UIImage *mask = [UIImage imageWithGradientOfSize:self.size startColor:[UIColor blackColor] endColor:[UIColor whiteColor] startPoint:0.7f endPoint:1];
  CGImageRef maskRef = mask.CGImage;
  CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(maskRef), CGImageGetHeight(maskRef), CGImageGetBitsPerComponent(maskRef), CGImageGetBitsPerPixel(maskRef), CGImageGetBytesPerRow(maskRef), CGImageGetDataProvider(maskRef), NULL, false);
  CGImageRef masked = CGImageCreateWithMask(imgRef, actualMask);
  UIImage *blurredImage = [UIImage imageWithCGImage:masked];

  CGImageRelease(actualMask);
  CGImageRelease(masked);

  return blurredImage;
}

- (UIImage *)fillScreenWithHeight:(CGFloat)height {
  return [self resizedImage:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), height)];
}

- (UIImage *)resizedImage:(CGRect)cropRect {
  UIImageView *resizedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(cropRect), CGRectGetHeight(cropRect))];
  resizedImageView.image = self;
  resizedImageView.contentMode = UIViewContentModeScaleAspectFill;
  UIGraphicsBeginImageContextWithOptions(resizedImageView.bounds.size, resizedImageView.opaque, 0);
  [resizedImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return resizedImage;
}

- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha {
  UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
  CGContextScaleCTM(ctx, 1, -1);
  CGContextTranslateCTM(ctx, 0, -area.size.height);
  CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
  CGContextSetAlpha(ctx, alpha);
  CGContextDrawImage(ctx, area, self.CGImage);
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

- (UIImage *)removeBlackBars {
  if ([self hasBlackBars]) {
    return [self crop:CGRectMake(0, self.size.height * (1 - 1 / 2.39f) / 2, self.size.width, self.size.height / 2.39f)];
  }
  return self;
}

- (BOOL)hasBlackBars {
  return [[self averageColorInRect:CGRectMake(0, 0, self.size.width, self.size.height * 0.1f)] isBlack];
}

- (UIColor *)averageColor {
  return [self averageColorInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
}

- (UIColor *)bottomColor {
  return [self averageColorInRect:CGRectMake(0, self.size.height * 0.9f, self.size.width, self.size.height * 0.1f)];
}

- (UIColor *)averageColorInRect:(CGRect)rect {
  CGImageRef tempImage = [self CGImage];
  CGImageRef bottomImage = CGImageCreateWithImageInRect(tempImage, rect);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  unsigned char rgba[4];
  CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

  CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), bottomImage);
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(context);
  CGImageRelease(bottomImage);

  if (rgba[3] > 0) {
    CGFloat alpha = ((CGFloat)rgba[3]) / 255;
    CGFloat multiplier = alpha / 255;
    return [UIColor colorWithRed:((CGFloat)rgba[0]) * multiplier
            green:((CGFloat)rgba[1]) * multiplier
            blue:((CGFloat)rgba[2]) * multiplier
            alpha:alpha];
  } else {
    return [UIColor colorWithRed:((CGFloat)rgba[0]) / 255
            green:((CGFloat)rgba[1]) / 255
            blue:((CGFloat)rgba[2]) / 255
            alpha:((CGFloat)rgba[3]) / 255];
  }
}

#pragma mark -

+ (UIImage *)imageWithColor:(UIColor *)color {
  CGRect rect = CGRectMake(0, 0, 1, 1);

  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, rect);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

+ (UIImage *)convertViewToImage {
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  CGRect rect = keyWindow.bounds;

  UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [keyWindow.layer renderInContext:context];
  UIImage *capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return capturedScreen;
}

+ (UIImage *)convertViewToImage:(UIView *)view {
  UIImage *capturedScreen;

  if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
    //Optimized/fast method for rendering a UIView as image on iOS 7 and later versions.
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  } else {
    //For devices running on earlier iOS versions.
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }

  return capturedScreen;
}

- (UIImage *)crop:(CGRect)rect {
  if (self.scale > 1) {
    rect = CGRectMake(rect.origin.x * self.scale, rect.origin.y * self.scale, rect.size.width * self.scale, rect.size.height * self.scale);
  }

  CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
  UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
  CGImageRelease(imageRef);
  return result;
}

+ (UIImage *)imageWithGradientOfSize:(CGSize)size startColor:(UIColor *)startColor endColor:(UIColor *)endColor startPoint:(CGFloat)startPoint endPoint:(CGFloat)endPoint {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGFloat locations[2] = {
    startPoint, endPoint
  };
  CFArrayRef colors = (__bridge CFArrayRef)@[(id)startColor.CGColor, (id)endColor.CGColor];

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);

  CGContextDrawLinearGradient(context, gradient, CGPointMake(0.5f, 0), CGPointMake(0.5f, size.height), kCGGradientDrawsAfterEndLocation);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);
  UIGraphicsEndImageContext();

  return image;
}

- (UIImage *)tintWithColor:(UIColor *)color {
  UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);

  CGContextScaleCTM(context, 1, -1);
  CGContextTranslateCTM(context, 0, -area.size.height);

  CGContextSaveGState(context);
  CGContextClipToMask(context, area, self.CGImage);

  [color set];
  CGContextFillRect(context, area);
  CGContextRestoreGState(context);
  CGContextSetBlendMode(context, kCGBlendModeMultiply);
  CGContextDrawImage(context, area, self.CGImage);

  UIImage *colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return colorizedImage;
}

@end
