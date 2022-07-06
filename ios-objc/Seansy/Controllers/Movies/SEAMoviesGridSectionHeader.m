#import "SEAMoviesGridSectionHeader.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"

@implementation SEAMoviesGridSectionHeader

#pragma mark Intializatoin

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
  toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  toolbar.barStyle = UIBarStyleBlack;

  self.label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(frame) - 20, CGRectGetHeight(frame))];
  self.label.textColor = [UIColor whiteColor];
  self.label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];

  [toolbar addSubview:self.label];
  [self addSubview:toolbar];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.label.text = nil;
}

@end
