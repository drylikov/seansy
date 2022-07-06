#import "UILabel+SEAHelpers.h"

#import "UIView+AYUtils.h"

@implementation UILabel (SEAHelpers)

#pragma mark Public

- (void)adjustFontSizeWithMaxLines:(NSUInteger)maxLines fontFloor:(CGFloat)fontFloor {
  while ([self overflows]) {
    self.font = [self.font fontWithSize:self.font.pointSize - 1];
  }
  while ([self sizeToFitWithHeightLimit:0].height > [self.text sizeWithAttributes:@{ NSFontAttributeName : self.font }].height * maxLines) {
    self.font = [self.font fontWithSize:self.font.pointSize - 1];
  }
  self.numberOfLines = 0;
  [self setFrameToFitWithHeightLimit:0];
}

- (void)setFrameToFitWithHeightLimit:(CGFloat)heightLimit {
  self.height = [self sizeToFitWithHeightLimit:heightLimit].height;
}

- (CGSize)sizeToFitWithHeightLimit:(CGFloat)heightLimit {
  NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  return ([self.text boundingRectWithSize:CGSizeMake(self.width, heightLimit) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{
             NSParagraphStyleAttributeName : paragraphStyle.copy,
             NSFontAttributeName : self.font
           } context:nil]).size;
}

#pragma mark Public

- (BOOL)overflows {
  NSArray *words = [self.text componentsSeparatedByString:@" "];
  BOOL overflows = NO;

  for (NSString *word in words) {
    CGFloat wordLength;
    if (![word isEqualToString:[words lastObject]]) {
      wordLength = [[word stringByAppendingString:@" "] sizeWithAttributes:@{ NSFontAttributeName : self.font }].width;
    } else {
      wordLength = [word sizeWithAttributes:@{ NSFontAttributeName : self.font }].width;
    }
    if (wordLength >= self.width) {
      overflows = YES;
    }
  }
  return overflows;
}

@end
