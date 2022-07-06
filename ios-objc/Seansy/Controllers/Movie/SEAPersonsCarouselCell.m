#import "SEAPersonsCarouselCell.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"

@implementation SEAPersonsCarouselCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

  self.placeholderLabel = [UILabel new];
  self.placeholderLabel.backgroundColor = [UIColor whiteColor];
  self.placeholderLabel.textColor = [UIColor colorWithHexString:kOnyxColor];
  self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
  self.placeholderLabel.font = [UIFont lightFontWithSize:[UIFont personsCarouselPlaceholderFontSize]];
  self.placeholderLabel.hidden = YES;

  self.photo = [UIImageView new];
  self.photo.contentMode = UIViewContentModeScaleToFill;
  self.photo.clipsToBounds = YES;

  self.nameLabel = [UILabel new];
  self.nameLabel.textColor = [UIColor whiteColor];
  self.nameLabel.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
  self.nameLabel.numberOfLines = 2;
  self.nameLabel.textAlignment = NSTextAlignmentCenter;
  self.nameLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
  self.nameLabel.shadowOffset = CGSizeMake(1, 1);
  self.nameLabel.adjustsFontSizeToFitWidth = YES;

  [self.contentView addSubview:self.loader];
  [self.contentView addSubview:self.placeholderLabel];
  [self.contentView addSubview:self.photo];
  [self.contentView addSubview:self.nameLabel];

  return self;
}

#pragma mark UICollectionReusableView

- (void)prepareForReuse {
  [super prepareForReuse];
  self.photo.image = nil;
  self.placeholderLabel.text = @"";
  self.placeholderLabel.hidden = YES;
  self.nameLabel.text = @"";
}

@end
