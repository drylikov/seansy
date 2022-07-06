#import "SEAMoviesGridCell.h"

#import "SEAConstants.h"
#import "SEAStarRatingView.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

CGFloat const kMoviesGridCellInfoHeight = 20;
CGFloat const kMoviesGridCellInfoTopMargin = 5;
CGFloat const kMoviesGridCellInfoBottomMargin = 5;

@interface SEAMoviesGridCell ()

@property (nonatomic) SEAStarRatingView *ratingStars;
@property (nonatomic) UIImageView *gradient;
@property (nonatomic) UILabel *ratingLabel;

@end

@implementation SEAMoviesGridCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.poster = [[UIImageView alloc] initWithFrame:self.bounds];
  self.poster.contentMode = UIViewContentModeScaleToFill;
  self.poster.clipsToBounds = YES;
  self.poster.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  self.gradient = [[UIImageView alloc] initWithImage:[UIImage imageWithGradientOfSize:CGSizeMake(self.width, self.height * 0.4f) startColor:[UIColor clearColor] endColor:[UIColor colorWithWhite:0 alpha:0.75f] startPoint:0 endPoint:1]];
  self.gradient.frame = CGRectMake(0, self.height * 0.4f, self.width, self.height * 0.6f);
  self.gradient.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
  self.gradient.hidden = YES;

  self.ratingStars = [[SEAStarRatingView alloc] initWithFrame:CGRectMake(0, self.height - kMoviesGridCellInfoHeight - kMoviesGridCellInfoBottomMargin, self.width * 0.8f, kMoviesGridCellInfoHeight)];
  self.ratingStars.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
  self.ratingStars.centerX = self.gradient.centerX;
  self.ratingStars.minimumValue = 0;
  self.ratingStars.maximumValue = 5;
  self.ratingStars.tintColor = [UIColor colorWithHexString:kAmberColor];
  self.ratingStars.hidden = YES;

  self.ratingLabel = [UILabel new];
  self.ratingLabel.textColor = [UIColor whiteColor];
  self.ratingLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.ratingLabel.textAlignment = NSTextAlignmentCenter;
  self.ratingLabel.layer.cornerRadius = 3;
  self.ratingLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
  self.ratingLabel.clipsToBounds = YES;
  self.ratingLabel.hidden = YES;

  [self.contentView addSubview:self.poster];
  [self.contentView addSubview:self.gradient];
  [self.contentView addSubview:self.ratingStars];
  [self.contentView addSubview:self.ratingLabel];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.poster.image = nil;
  self.gradient.hidden = YES;
  self.ratingStars.hidden = YES;
  self.ratingLabel.hidden = YES;
  self.ratingLabel.textColor = [UIColor whiteColor];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self.ratingLabel sizeToFit];
  self.ratingLabel.width += 8;
  self.ratingLabel.height += 4;
  self.ratingLabel.center = self.ratingStars.center;
  [self.ratingStars setNeedsLayout];
}

#pragma mark Setters

- (void)setMovie:(SEAMovie *)movie {
  _movie = movie;
  [self.poster sd_setImageWithURL:movie.poster.url placeholderImage:[UIImage imageNamed:@"PosterPlaceholder"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    if (cacheType == SDImageCacheTypeNone) {
      self.poster.alpha = 0;
      [UIView animateWithDuration:0.3f animations:^{
        self.poster.alpha = 1;
      }];
    }
  }];
  if ([movie isPlaying]) {
    BOOL percents = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kShowPercentRatingsKey];
    CGFloat averageRating = movie.averageRating;
    if (averageRating > 0) {
      self.gradient.hidden = NO;
      if (percents) {
        self.ratingLabel.text = [NSString stringWithFormat:@"%.1f%%", averageRating];
        self.ratingLabel.hidden = NO;
        if (averageRating >= 60) {
          self.ratingLabel.textColor = [UIColor colorWithHexString:kGreenColor];
        } else {
          self.ratingLabel.textColor = [UIColor colorWithHexString:kRedColor];
        }
        [self setNeedsLayout];
      } else {
        self.ratingStars.value = averageRating / 20;
        self.ratingStars.hidden = NO;
      }
    }
  }
}

#pragma mark SEAPosterViewDelegate

- (void)restorePoster {
  self.poster.alpha = 1;
}

@end
