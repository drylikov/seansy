#import "SEAShowtimesItemCell.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"

@implementation SEAShowtimesItemCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.layer.borderWidth = 1;
  self.layer.borderColor = [UIColor whiteColor].CGColor;
  self.layer.cornerRadius = 5;
  self.clipsToBounds = YES;

  self.label = [UILabel new];
  self.label.numberOfLines = 0;
  self.label.textColor = [UIColor whiteColor];
  self.label.textAlignment = NSTextAlignmentCenter;

  [self.contentView addSubview:self.label];

  return self;
}

#pragma mark Setters

- (void)setColor:(UIColor *)color {
  _color = color;
  self.label.textColor = color;
  self.layer.borderColor = color.CGColor;
}

#pragma mark Public

- (void)resetView {
  self.label.textColor = self.color;
  self.layer.backgroundColor = nil;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.label.text = @"";
  self.alpha = 1;
  [self resetView];
}

@end
