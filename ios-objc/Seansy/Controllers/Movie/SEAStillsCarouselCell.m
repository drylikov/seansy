#import "SEAStillsCarouselCell.h"

@implementation SEAStillsCarouselCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

  self.photo = [UIImageView new];
  self.photo.contentMode = UIViewContentModeScaleToFill;
  self.photo.clipsToBounds = YES;

  [self.contentView addSubview:self.loader];
  [self.contentView addSubview:self.photo];

  return self;
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.loader.frame = self.bounds;
  self.photo.frame = self.bounds;
}

#pragma mark UICollectionReusableView

- (void)prepareForReuse {
  [super prepareForReuse];
  self.photo.image = nil;
}

@end
