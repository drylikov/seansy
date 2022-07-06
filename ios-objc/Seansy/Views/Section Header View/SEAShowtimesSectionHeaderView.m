#import "SEAShowtimesSectionHeaderView.h"

#import "DRViewSlideGestureRecognizer.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

CGFloat const kShowtimesSectionHeaderViewArrowIconLeftMargin = 10;
CGSize const kShowtimesSectionHeaderViewArrowIconSize = {
  20, 2
};
UIEdgeInsets const kShowtimesSectionHeaderViewPadding = {
  0, 10, 0, 10
};

@interface SEAShowtimesSectionHeaderView ()

@property (nonatomic) BOOL hasSubtitle;
@property (nonatomic) DRViewSlideGestureRecognizer *slideGestureRecognizer;
@property (nonatomic) UIImageView *star;

@end

@implementation SEAShowtimesSectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithReuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.backgroundView = [UIView new];
  self.backgroundView.backgroundColor = [UIColor colorWithHexString:kDarkOnyxColor];
  self.contentView.backgroundColor = [UIColor colorWithHexString:kDarkOnyxColor];

  self.backdrop = [UIImageView new];
  self.backdrop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.backdrop.contentMode = UIViewContentModeScaleAspectFill;
  self.backdrop.userInteractionEnabled = YES;
  self.backdrop.clipsToBounds = YES;

  self.title = [UILabel new];
  self.title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.title.textColor = [UIColor whiteColor];

  self.subtitle = [UILabel new];
  self.subtitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.subtitle.textColor = [UIColor colorWithWhite:1 alpha:0.75f];
  self.subtitle.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
  self.subtitle.numberOfLines = 1;

  self.hasSubtitle = YES;

  [self.contentView addSubview:self.backdrop];
  [self.contentView addSubview:self.title];
  [self.contentView addSubview:self.subtitle];

  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
  [self addGestureRecognizer:tapGestureRecognizer];

  return self;
}

#pragma mark UITableViewHeaderFooterView

- (void)prepareForReuse {
  self.backdrop.image = nil;
  [self removeGestureRecognizer:self.slideGestureRecognizer];
  [self.poster removeFromSuperview];
  [self.star removeFromSuperview];
  [self.arrowIcon removeFromSuperview];
  self.hasSubtitle = YES;
  for (UILabel *label in @[self.title, self.subtitle]) {
    label.text = @"";
  }

  self.subtitle.textColor = [UIColor colorWithWhite:1 alpha:0.75f];
  self.delegate = nil;
  _movie = nil;
  _theatre = nil;
}

#pragma mark UIView

- (void)layoutSubviews {
  self.backgroundView.frame = self.bounds;
  self.backdrop.frame = CGRectMake(0, 0, self.width, self.height - 1 / [UIScreen mainScreen].scale);
  if (self.movie || self.theatre) {
    [self fixLayout];
  }
}

#pragma mark Public

- (void)startFloatAnimation {
  [UIView animateWithDuration:0.8f delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionAllowUserInteraction animations:^{
    self.poster.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
  } completion:nil];
}

- (void)stopFloatAnimation {
  [self.poster.layer removeAllAnimations];
  self.poster.transform = CGAffineTransformIdentity;
}

- (void)setUpArrowIconWithOrientation:(SEAArrowIconOrientation)orientation {
  if (orientation == SEAArrowIconOrientationHorizontal) {
    self.arrowIcon = [[SEAArrowIcon alloc] initWithFrame:CGRectMake(self.width - kShowtimesSectionHeaderViewArrowIconSize.width - kShowtimesSectionHeaderViewPadding.right, (self.backdrop.height - kShowtimesSectionHeaderViewArrowIconSize.height) / 2, kShowtimesSectionHeaderViewArrowIconSize.width, kShowtimesSectionHeaderViewArrowIconSize.height) orientation:SEAArrowIconOrientationHorizontal];
    [self.arrowIcon pointDownAnimated:NO];
  } else {
    self.arrowIcon = [[SEAArrowIcon alloc] initWithFrame:CGRectMake(self.width - kShowtimesSectionHeaderViewArrowIconSize.height - kShowtimesSectionHeaderViewPadding.right, (self.backdrop.height - kShowtimesSectionHeaderViewArrowIconSize.width) / 2, kShowtimesSectionHeaderViewArrowIconSize.height, kShowtimesSectionHeaderViewArrowIconSize.width) orientation:SEAArrowIconOrientationVertical];
    [self.arrowIcon pointRightAnimated:NO];
  }

  self.arrowIcon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
  [self.contentView addSubview:self.arrowIcon];
}

#pragma mark Setters

- (void)setMovie:(SEAMovie *)movie {
  _movie = movie;
  self.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kMovieSectionHeaderViewHeight);

  [movie.backdrop getFilteredImageWithProgressBlock:nil completionBlock:^(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache) {
    if (movie == self.movie) {
      if (filteredImage) {
        self.backdrop.image = filteredImage;
        if (!fromCache) {
          self.backdrop.alpha = 0;
          [UIView animateWithDuration:0.4f animations:^{
            self.backdrop.alpha = 0.6f;
          }];
        } else {
          self.backdrop.alpha = 0.6f;
        }
      }
      [movie.backdrop getColorsWithCompletionBlock:^(NSDictionary *colors) {
        self.subtitle.textColor = movie.backdrop.colors[kBackdropTextColorKey];
      }];
    }
  }];

  self.poster = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.backdrop.height * 0.7f, self.backdrop.height)];
  self.poster.contentMode = UIViewContentModeScaleToFill;
  self.poster.clipsToBounds = YES;
  self.poster.userInteractionEnabled = YES;
  [self.contentView addSubview:self.poster];

  [self.poster sd_setImageWithURL:movie.poster.url placeholderImage:[UIImage imageNamed:@"PosterPlaceholder"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    if (cacheType == SDImageCacheTypeNone) {
      self.poster.alpha = 0;
      [UIView animateWithDuration:0.3f animations:^{
        self.poster.alpha = 1;
      }];
    }
  }];

  for (UILabel *label in @[self.title, self.subtitle]) {
    label.frame = CGRectMake(kShowtimesSectionHeaderViewPadding.left + self.poster.right, 0, self.width - kShowtimesSectionHeaderViewPadding.left - kShowtimesSectionHeaderViewArrowIconLeftMargin - kShowtimesSectionHeaderViewArrowIconSize.width - kShowtimesSectionHeaderViewPadding.right - self.poster.right, 0);
  }

  self.title.font = [UIFont lightFontWithSize:[UIFont movieSectionHeaderFontSize]];
  self.title.text = movie.title;
  NSString *subtitleText = [movie subtitle];
  if (subtitleText) {
    self.subtitle.text = subtitleText;
  } else {
    self.hasSubtitle = NO;
  }

  [self fixLayout];
}

- (void)setTheatre:(SEATheatre *)theatre {
  _theatre = theatre;
  self.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kTheatreSectionHeaderViewHeight);

  [theatre.backdrop getFilteredImageWithProgressBlock:nil completionBlock:^(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache) {
    if (theatre == self.theatre && filteredImage) {
      self.backdrop.image = filteredImage;
      if (!fromCache) {
        self.backdrop.alpha = 0;
        [UIView animateWithDuration:0.4f animations:^{
          self.backdrop.alpha = 0.6f;
        }];
      } else {
        self.backdrop.alpha = 0.6f;
      }
    }
  }];

  self.title.font = [UIFont lightFontWithSize:[UIFont theatreSectionHeaderFontSize]];
  self.title.text = theatre.name;
  NSString *subtitleText = [theatre subtitle];
  if (subtitleText) {
    self.subtitle.text = subtitleText;
  } else {
    self.hasSubtitle = NO;
  }

  [self addSlideGestureRecognizer];
  [self updateStar];
}

- (void)updateStar {
  if (self.theatre.isFavorite) {
    self.star = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"StarIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.star.left = kShowtimesSectionHeaderViewPadding.left;
    self.star.centerY = self.backdrop.centerY;
    self.star.tintColor = [UIColor colorWithHexString:kAmberColor];
    [self.contentView addSubview:self.star];
  } else {
    [self.star removeFromSuperview];
  }

  for (UILabel *label in @[self.title, self.subtitle]) {
    label.frame = CGRectMake((self.theatre.isFavorite ? self.star.right : 0) + kShowtimesSectionHeaderViewPadding.left, 0, self.width - kShowtimesSectionHeaderViewPadding.left - kShowtimesSectionHeaderViewArrowIconLeftMargin - kShowtimesSectionHeaderViewArrowIconSize.width - kShowtimesSectionHeaderViewPadding.right - (self.theatre.isFavorite ? self.star.right : 0), 0);
  }

  [self fixLayout];
}

- (void)addSlideGestureRecognizer {
  [self removeGestureRecognizer:self.slideGestureRecognizer];
  self.slideGestureRecognizer = [DRViewSlideGestureRecognizer new];
  DRViewSlideAction *action = [DRViewSlideAction actionForFraction:0.25f];
  action.behavior = DRViewSlideActionPullBehavior;
  action.inactiveBackgroundColor = [UIColor colorWithHexString:kLightGreyColor];
  action.activeBackgroundColor = [UIColor colorWithHexString:kAmberColor];
  action.inactiveColor = action.activeColor = [UIColor colorWithHexString:kOnyxColor];
  action.icon = [UIImage imageNamed:@"StarIconFill"];
  action.title = self.theatre.favorite ? NSLocalizedString(@"Убрать", nil) : NSLocalizedString(@"Добавить", nil);
  action.willTriggerBlock = ^{
    self.theatre.favorite = !self.theatre.isFavorite;
    [self updateStar];
  };
  action.didTriggerBlock = ^{
    [self addSlideGestureRecognizer];
    [self.delegate sectionHeaderViewStarred:self];
  };
  [self.slideGestureRecognizer addActions:action];
  [self addGestureRecognizer:self.slideGestureRecognizer];
}

#pragma mark Private

- (void)fixLayout {
  self.title.top = 0;
  [self.title adjustFontSizeWithMaxLines:2 fontFloor:[UIFont largeTextFontSize]];
  if (self.hasSubtitle) {
    [self.subtitle setFrameToFitWithHeightLimit:20];
    self.subtitle.top = self.title.bottom + 4;
    CGFloat verticalOffset = (self.backdrop.height - self.subtitle.bottom - 4) / 2;
    self.title.top += verticalOffset;
    self.subtitle.top += verticalOffset;
  } else {
    self.title.top = (self.backdrop.height - self.title.height) / 2;
  }
}

- (void)tapped:(UITapGestureRecognizer *)tapGestureRecognizer {
  if (!self.delegate) {
    return;
  }

  CGPoint tapLocation = [tapGestureRecognizer locationInView:self.contentView];

  if (CGRectContainsPoint(self.poster.frame, tapLocation)) {
    [self.delegate sectionHeaderViewPosterTapped:self];
  } else {
    [self.delegate sectionHeaderViewBackdropTapped:self];
  }
}

#pragma mark SEAPosterViewDelegate

- (void)restorePoster {
  self.poster.alpha = 1;
}

@end
