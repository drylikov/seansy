#import "SEABackdrop.h"

#import "CCColorCube.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "UIColor+SEAHelpers.h"
#import "UIImage+SEAHelpers.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation SEABackdrop

#pragma mark Initialization

- (instancetype)initWithUrl:(NSURL *)url {
  self = [super init];
  if (!self) {
    return nil;
  }

  _url = url;
  _colors = [@{
               kBackdropTextColorKey : [UIColor colorWithWhite:1 alpha:0.75f],
               kBackdropBackgroundColorKey : [UIColor blackColor]
             } mutableCopy];
  _colorsExtracted = NO;

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _url = [decoder decodeObjectForKey:kBackdropUrlKey];
  _colors = [@{
               kBackdropTextColorKey : [decoder decodeObjectForKey:kBackdropTextColorKey],
               kBackdropBackgroundColorKey : [decoder decodeObjectForKey:kBackdropBackgroundColorKey]
             } mutableCopy];
  _colorsExtracted = [[decoder decodeObjectForKey:kBackdropColorsExtractedKey] boolValue];

  return self;
}

#pragma mark Public

- (void)getOriginalImageWithProgressBlock:(void (^)(CGFloat progress))progressBlock completionBlock:(void (^)(UIImage *originalImage, BOOL fromCache))completionBlock {
  if (!self.url) {
    if (completionBlock) {
      completionBlock(nil, NO);
    }
    return;
  } else if (self.originalImage) {
    if (completionBlock) {
      completionBlock(self.originalImage, YES);
    }
    return;
  }
  SDWebImageManager *manager = [SDWebImageManager sharedManager];
  [manager downloadImageWithURL:self.url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
    if (progressBlock) {
      CGFloat progress = (CGFloat)receivedSize / (CGFloat)expectedSize;
      progressBlock(progress);
    }
  } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
      self->_originalImage = [image removeBlackBars];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (completionBlock) {
          completionBlock(self.originalImage, cacheType != SDImageCacheTypeNone);
        }
      });
    });
  }];
}

- (void)getFilteredImageWithProgressBlock:(void (^)(CGFloat progress))progressBlock completionBlock:(void (^)(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache))completionBlock {
  if (self.filteredImage && self.originalImage) {
    if (completionBlock) {
      completionBlock(self.filteredImage, self.originalImage, YES);
    }
    return;
  }
  [self getOriginalImageWithProgressBlock:progressBlock completionBlock:^(UIImage *originalImage, BOOL fromCache) {
    if (!originalImage) {
      if (completionBlock) {
        completionBlock(nil, nil, NO);
      }
      return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
      self->_filteredImage = [originalImage tintWithColor:[UIColor colorWithWhite:0 alpha:kBackdropBlurDarkeningRatio]];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (completionBlock) {
          completionBlock(self.filteredImage, originalImage, NO);
        }
      });
    });
  }];
}

- (void)getColorsWithCompletionBlock:(void (^)(NSDictionary *colors))completionBlock {
  if (!self.colorsExtracted) {
    [self getFilteredImageWithProgressBlock:nil completionBlock:^(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache) {
      if (!filteredImage) {
        if (completionBlock) {
          completionBlock(self.colors);
        }
        return;
      }
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
        CCColorCube *colorCube = [CCColorCube new];
        NSArray *dominantColors = [colorCube extractColorsFromImage:filteredImage flags:CCAvoidWhite];
        if (dominantColors.count > 0) {
          BOOL set = NO;
          for (NSUInteger i = 0; i < dominantColors.count; i++) {
            UIColor *testColor = dominantColors[i];
            if ([testColor isContrastingColor:[UIColor whiteColor]]) {
              self.colors[kBackdropBackgroundColorKey] = testColor;
              set = YES;
              break;
            }
          }
          if (!set && [[filteredImage bottomColor] isContrastingColor:[UIColor whiteColor]]) {
            self.colors[kBackdropBackgroundColorKey] = [filteredImage bottomColor];
          }
        } else if ([[filteredImage bottomColor] isContrastingColor:[UIColor whiteColor]]) {
          self.colors[kBackdropBackgroundColorKey] = [filteredImage bottomColor];
        }
        NSArray *brightColors = [colorCube extractColorsFromImage:originalImage flags:CCOnlyDistinctColors | CCOrderByBrightness | CCOnlyBrightColors | CCAvoidWhite];
        if (brightColors.count > 0) {
          for (NSUInteger i = 0; i < brightColors.count; i++) {
            UIColor *testColor = [(UIColor *)brightColors[i] darkerColor:0.1f];
            if (![testColor isDarkColor] && [testColor isContrastingColor:self.colors[kBackdropBackgroundColorKey]]) {
              self.colors[kBackdropTextColorKey] = testColor;
              break;
            }
          }
        }
        self->_colorsExtracted = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completionBlock) {
            completionBlock(self.colors);
          }
        });
      });
    }];
  } else if (completionBlock) {
    completionBlock(self.colors);
  }
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.url forKey:kBackdropUrlKey];
  [coder encodeObject:self.colors[kBackdropTextColorKey] forKey:kBackdropTextColorKey];
  [coder encodeObject:self.colors[kBackdropBackgroundColorKey] forKey:kBackdropBackgroundColorKey];
  [coder encodeObject:@(self.colorsExtracted) forKey:kBackdropColorsExtractedKey];
}

@end
