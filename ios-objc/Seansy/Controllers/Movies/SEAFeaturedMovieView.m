#import "SEAFeaturedMovieView.h"

#import "SEAStarRatingView.h"
#import "UIView+AYUtils.h"
#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

CGFloat const kFeaturedMovieViewRatingHeight = 20;
CGFloat const kFeaturedMovieViewTitleLabelVerticalMargin = 5;
UIEdgeInsets const kFeaturedMovieViewPadding = {
  10, 10, 10, 10
};


@interface SEAFeaturedMovieView ()

@property (nonatomic) SEAMovie *movie;
@property (nonatomic) UIImageView *gradient;
@property (nonatomic) SEAStarRatingView *ratingStars;
@property (nonatomic) UIImageView *backdrop;
@property (nonatomic) UILabel *ratingLabel;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation SEAFeaturedMovieView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backdrop = [[UIImageView alloc] initWithFrame:self.bounds];
  self.backdrop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.backdrop.contentMode = UIViewContentModeScaleAspectFill;
  self.backdrop.clipsToBounds = YES;

  self.gradient = [[UIImageView alloc] initWithImage:[UIImage imageWithGradientOfSize:CGSizeMake(self.width, self.height * 0.4f) startColor:[UIColor clearColor] endColor:[UIColor colorWithWhite:0 alpha:0.75f] startPoint:0 endPoint:1]];
  self.gradient.frame = CGRectMake(0, self.backdrop.height * 0.2f, self.backdrop.width, self.backdrop.height * 0.8f);
  self.gradient.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFeaturedMovieViewPadding.left, 0, self.backdrop.width - kFeaturedMovieViewPadding.left - kFeaturedMovieViewPadding.right, 0)];
  self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.font = [UIFont lightFontWithSize:[UIFont featuredMovieTitleFontSize]];

  self.ratingStars = [[SEAStarRatingView alloc] initWithFrame:CGRectMake(kFeaturedMovieViewPadding.left, 0, kFeaturedMovieViewRatingHeight * 5, kFeaturedMovieViewRatingHeight)];
  self.ratingStars.bottom = self.backdrop.height - kFeaturedMovieViewPadding.bottom;
  self.ratingStars.minimumValue = 0;
  self.ratingStars.maximumValue = 5;
  self.ratingStars.tintColor = [UIColor colorWithHexString:kAmberColor];
  self.ratingStars.hidden = YES;

  self.ratingLabel = [UILabel new];
  self.ratingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.ratingLabel.textColor = [UIColor whiteColor];
  self.ratingLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.ratingLabel.textAlignment = NSTextAlignmentCenter;
  self.ratingLabel.layer.cornerRadius = 3;
  self.ratingLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
  self.ratingLabel.clipsToBounds = YES;
  self.ratingLabel.hidden = YES;

  [self.backdrop addSubview:self.gradient];
  [self.backdrop addSubview:self.titleLabel];
  [self.backdrop addSubview:self.ratingStars];
  [self.backdrop addSubview:self.ratingLabel];
  [self addSubview:self.backdrop];

  return self;
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  [self.titleLabel adjustFontSizeWithMaxLines:2 fontFloor:[UIFont largeTextFontSize]];
  if (self.ratingStars.hidden && self.ratingLabel.hidden) {
    self.titleLabel.bottom = self.backdrop.height - kFeaturedMovieViewPadding.bottom;
  } else if (self.ratingStars.hidden) {
    [self.ratingLabel sizeToFit];
    self.ratingLabel.width += 8;
    self.ratingLabel.height += 4;
    self.ratingLabel.left = kFeaturedMovieViewPadding.left;
    self.ratingLabel.bottom = self.backdrop.height - kFeaturedMovieViewPadding.bottom;
    self.titleLabel.bottom = self.ratingLabel.top - kFeaturedMovieViewTitleLabelVerticalMargin;
  } else {
    self.titleLabel.bottom = self.ratingStars.top - kFeaturedMovieViewTitleLabelVerticalMargin;
  }
}

#pragma mark Public

- (RACSignal *)updateMovie:(SEAMovie *)movie {
  self.movie = movie;
  self.titleLabel.text = movie.title;
  CGFloat averageRating = movie.averageRating;
  if (averageRating > 0) {
    self.gradient.hidden = NO;
    if (self.shouldUsePercents) {
      self.ratingLabel.text = [NSString stringWithFormat:@"%.1f%%", averageRating];
      self.ratingLabel.hidden = NO;
      if (averageRating >= 60) {
        self.ratingLabel.textColor = [UIColor colorWithHexString:kGreenColor];
      } else {
        self.ratingLabel.textColor = [UIColor colorWithHexString:kRedColor];
      }
    } else {
      self.ratingStars.value = averageRating / 20;
      self.ratingStars.hidden = NO;
    }
  }
  [self setNeedsLayout];
  SDWebImageManager *manager = [SDWebImageManager sharedManager];
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [manager downloadImageWithURL:movie.backdrop.url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
      self.backdrop.image = image;
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

@end
