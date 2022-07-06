#import "SEAMoviesFilterGenresSelectorCell.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"

@implementation SEAMoviesFilterGenresSelectorCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor clearColor];

  self.label = [UILabel new];
  self.label.textColor = [UIColor whiteColor];
  self.label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.label.textAlignment = NSTextAlignmentCenter;
  self.label.layer.borderWidth = 1;
  self.label.layer.borderColor = [UIColor colorWithHexString:kAmberColor].CGColor;
  self.label.layer.cornerRadius = 5;

  [self.contentView addSubview:self.label];
  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.label.text = nil;
  self.label.textColor = [UIColor whiteColor];
  self.label.layer.backgroundColor = [UIColor clearColor].CGColor;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.label.frame = self.contentView.bounds;
}

#pragma mark Setters

- (void)setActive:(BOOL)active {
  _active = active;
  if (_active) {
    self.label.layer.backgroundColor = [UIColor colorWithHexString:kAmberColor].CGColor;
    self.label.textColor = [UIColor blackColor];
  } else {
    self.label.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.label.textColor = [UIColor whiteColor];
  }
}

@end
