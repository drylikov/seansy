//
//  Copyright (c) 2013 Byte, 2014 Ayan Yenbekbay.
//

#import "SEAGlassScrollView.h"

#import "NSString+SEAHelpers.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAProgressView.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UIView+AYUtils.h"

static CGFloat const kMoviePlayButtonSize = 75;
static CGFloat const kMovieTopFadingHeightHalf = 10;
static CGFloat const kMovieBackdropMaxMovementVertical = 30;
static UIEdgeInsets const kMovieShowtimesButtonPadding = {
  10, 15, 10, 15
};
static CGFloat const kMovieShowtimesButtonTopMargin = 10;
static CGFloat const kMovieShowtimesButtonBottomMargin = 20;

@interface SEAGlassScrollView ()

@property (nonatomic) BOOL playIconPressed;
@property (nonatomic) CGFloat pagingScrollVelocity;
@property (nonatomic) CGFloat trailerPlayCenter;
@property (nonatomic) SEAProgressView *backdropProgressView;
@property (nonatomic) UIButton *showtimesButton;
@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIImage *backdropImage;
@property (nonatomic) UIImage *blurredBackdropImage;
@property (nonatomic) UIImageView *backdropImageView;
@property (nonatomic) UIImageView *blurredBackdropImageView;
@property (nonatomic) UIImageView *playIconImageView;
@property (nonatomic) UIScrollView *backdropScrollView;
@property (nonatomic) UIScrollView *containerScrollView;
@property (nonatomic) UIScrollView *infoScrollView;
@property (nonatomic) UIScrollView *showtimesScrollView;
@property (weak, nonatomic) SEAMovieDetailsInfoView *infoView;
@property (weak, nonatomic) SEAMovieShowtimesView *showtimesView;

@end

@implementation SEAGlassScrollView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame infoView:(SEAMovieDetailsInfoView *)infoView showtimesView:(SEAMovieShowtimesView *)showtimesView {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor blackColor];
  self.infoView = infoView;
  self.showtimesView = showtimesView;
  self.currentPageIndex = 0;
  [self setUpBackdropView];
  [self setUpInfoView];

  return self;
}

#pragma mark Setters

- (void)setDelegate:(id<SEAGlassScrollViewDelegate>)delegate {
  _delegate = delegate;
  [self updateContainerScrollViewMask];
  if (self.showtimesScrollView) {
    [self updateShowtimesScrollViewContentSize];
  }
}

- (void)setMovie:(SEAMovie *)movie {
  _movie = movie;
  [movie.backdrop getFilteredImageWithProgressBlock:^(CGFloat progress) {
    if (progress < 1) {
      [self setBackdropProgress:progress];
    }
  } completionBlock:^(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache) {
    if (filteredImage) {
      CGFloat backdropHeight = self.height;
      // Darken the image and set the size
      if (![self isInLandscape]) {
        backdropHeight -= self.infoView.summaryHeight;
        self.backdropImage = [[filteredImage applyBlurToEdges] fillScreenWithHeight:backdropHeight];
        self.blurredBackdropImage = [[[filteredImage applyBlurWithRadius:kBackdropBlurRadius tintColor:nil saturationDeltaFactor:1 maskImage:nil] applyBlurToEdges] fillScreenWithHeight:backdropHeight];
      } else {
        self.backdropImage = [filteredImage fillScreenWithHeight:backdropHeight];
        self.blurredBackdropImage = [[filteredImage applyBlurWithRadius:kBackdropBlurRadius tintColor:nil saturationDeltaFactor:1 maskImage:nil] fillScreenWithHeight:backdropHeight];
      }
    }

    [movie.backdrop getColorsWithCompletionBlock:^(NSDictionary *colors) {
      self.backgroundColor = colors[kBackdropBackgroundColorKey];
      [self setUpBackdropImageViews];

      NSUInteger showtimesCount = [[SEADataManager sharedInstance] localShowtimesForMovie:movie].count;
      if (showtimesCount > 0) {
        [self setUpShowtimesButton];
        self.showtimesScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.showtimesScrollView.left = self.infoScrollView.width;
        self.showtimesScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        self.showtimesScrollView.delegate = self;
        self.showtimesView.containerView = self.showtimesScrollView;
        [self.showtimesView refresh];
        self.showtimesView.top += self.height - self.infoView.summaryHeight;
        [self updateShowtimesScrollViewContentSize];
        [self.showtimesScrollView addSubview:self.showtimesView];
        [self.containerScrollView addSubview:self.showtimesScrollView];
        self.containerScrollView.contentSize = CGSizeMake(self.showtimesScrollView.right, self.containerScrollView.height);
        [self updateContainerScrollViewMask];

        // Adding gesture recognizers
        UITapGestureRecognizer *tapGestureRecognize = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showtimesTapped:)];
        [self.showtimesScrollView addGestureRecognizer:tapGestureRecognize];
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showtimesPressed:)];
        [self.showtimesScrollView addGestureRecognizer:longPressGestureRecognizer];

        [self updateContainerScrollViewMask];
      }
    }];
  }];
}

#pragma mark Private

- (void)setUpBackdropView {
  self.backdropScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.backdropScrollView.userInteractionEnabled = NO;
  self.backdropScrollView.contentSize = CGSizeMake(self.backdropScrollView.width, self.height + kMovieBackdropMaxMovementVertical);
  [self addSubview:self.backdropScrollView];
}

- (void)setUpInfoView {
  self.containerScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.containerScrollView.showsHorizontalScrollIndicator = NO;
  self.containerScrollView.scrollEnabled = NO;
  self.containerScrollView.delegate = self;
  self.containerScrollView.contentSize = CGSizeMake(self.containerScrollView.width, self.containerScrollView.height);
  [self addSubview:self.containerScrollView];

  self.infoScrollView = [[UIScrollView alloc] initWithFrame:self.containerScrollView.bounds];
  self.infoScrollView.delegate = self;
  self.infoScrollView.showsVerticalScrollIndicator = NO;
  [self.containerScrollView addSubview:self.infoScrollView];

  self.infoView.left += (self.infoScrollView.width - self.infoView.width) / 2;
  self.infoView.top += self.height - self.infoView.summaryHeight;
  self.infoScrollView.contentSize = CGSizeMake(self.infoScrollView.width, self.infoView.bottom);
  [self.infoScrollView addSubview:self.infoView];

  // Adding gesture recognizers
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoTapped:)];
  [self.infoScrollView addGestureRecognizer:tapGestureRecognizer];

  UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(infoPressed:)];
  [self.infoScrollView addGestureRecognizer:longPressGestureRecognizer];
}

- (void)setUpBackdropImageViews {
  CGFloat ratio = self.infoScrollView.contentOffset.y / (self.infoScrollView.height - self.infoView.summaryHeight);

  ratio = ratio < 0 ? 0 : ratio;
  ratio = ratio > 1 ? 1 : ratio;

  if (self.backdropImage && self.blurredBackdropImage) {
    self.backdropImageView = [[UIImageView alloc] initWithImage:self.backdropImage];
    self.blurredBackdropImageView = [[UIImageView alloc] initWithImage:self.blurredBackdropImage];
    self.blurredBackdropImageView.alpha = ratio;
    self.backdropImageView.alpha = 1 - ratio;
    if (![self isInLandscape]) {
      self.backdropScrollView.contentOffset = CGPointMake(0, ratio * kMovieBackdropMaxMovementVertical);
      self.blurredBackdropImageView.alpha *= 1 - ratio * 0.4f;
    } else {
      self.blurredBackdropImageView.alpha *= 0.6f;
      self.backdropImageView.alpha *= 0.6f;
    }
    for (UIImageView *imageView in @[self.backdropImageView, self.blurredBackdropImageView]) {
      imageView.height = self.backdropScrollView.contentSize.height;
      imageView.contentMode = UIViewContentModeTop;
      imageView.backgroundColor = self.backgroundColor;
      if (self.backdropProgressView) {
        [self.backdropScrollView insertSubview:imageView belowSubview:self.backdropProgressView];
      } else {
        [self.backdropScrollView addSubview:imageView];
      }
    }
  }

  if (self.movie.trailerId) {
    self.playIconImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"PlayIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.playIconImageView.tintColor = [UIColor whiteColor];
    self.playIconImageView.frame = CGRectMake(0, 0, kMoviePlayButtonSize, kMoviePlayButtonSize);
    self.playIconImageView.alpha = 0.6f;
    self.playIconImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1 - ratio), (1 - ratio));
    self.playIconImageView.centerY = (self.height - self.infoView.summaryHeight) / 2 * (1 - ratio);
    self.playIconImageView.centerX = self.centerX;
    if (self.backdropProgressView) {
      [self.backdropScrollView insertSubview:self.playIconImageView belowSubview:self.backdropProgressView];
    } else {
      [self.backdropScrollView addSubview:self.playIconImageView];
    }
  }

  [self setBackdropProgress:1];
}

- (void)setUpBackdropProgressView {
  self.backdropProgressView = [[SEAProgressView alloc] initWithFrame:self.backdropScrollView.frame];
  self.backdropProgressView.spinnerHeight = self.height - self.infoView.summaryHeight;
  [self.backdropScrollView addSubview:self.backdropProgressView];
  [self.backdropScrollView bringSubviewToFront:self.backdropProgressView];
}

- (void)setUpShowtimesButton {
  self.showtimesButton = [UIButton new];
  self.showtimesButton.clipsToBounds = YES;
  UIColor *color = [UIColor colorWithHexString:kAmberColor];
  if (![self.movie.backdrop.colors[kBackdropTextColorKey] isEqualToColor:[UIColor colorWithWhite:1 alpha:0.75f]]) {
    color = self.movie.backdrop.colors[kBackdropTextColorKey];
  }
  [self.showtimesButton setBackgroundImage:[UIImage imageWithColor:color] forState:UIControlStateNormal];
  [self.showtimesButton setBackgroundImage:[UIImage imageWithColor:[color darkerColor:0.1f]] forState:UIControlStateHighlighted];
  NSUInteger theatresCount = [[SEADataManager sharedInstance] localTheatresForMovie:self.movie].count;
  NSString *showtimesButtonText = [NSString stringWithFormat:@"%@ %@", @(theatresCount), [NSString getNumEnding:(NSInteger)theatresCount endings:@[@"кинотеатр", @"кинотеатра", @"кинотеатров"]]];
  [self.showtimesButton setTitle:showtimesButtonText forState:UIControlStateNormal];
  [self.showtimesButton setTitleColor:[UIColor colorWithHexString:kOnyxColor] forState:UIControlStateNormal];
  [self.showtimesButton addTarget:self action:@selector(showtimesButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  self.showtimesButton.titleLabel.font = [UIFont regularFontWithSize:[UIFont largeTextFontSize]];
  CGSize showtimesButtonSize = [showtimesButtonText sizeWithAttributes:@{ NSFontAttributeName : self.showtimesButton.titleLabel.font }];
  self.showtimesButton.width = kMovieShowtimesButtonPadding.left + showtimesButtonSize.width + kMovieShowtimesButtonPadding.right;
  self.showtimesButton.height = kMovieShowtimesButtonPadding.top + showtimesButtonSize.height + kMovieShowtimesButtonPadding.bottom;
  self.showtimesButton.layer.cornerRadius = self.showtimesButton.height / 2;
  self.showtimesButton.bottom = self.height - kMovieShowtimesButtonBottomMargin;
  self.showtimesButton.centerX = self.centerX;
  [self addSubview:self.showtimesButton];

  self.infoScrollView.contentInset = UIEdgeInsetsMake(self.infoScrollView.contentInset.top, 0, kMovieShowtimesButtonTopMargin + self.showtimesButton.height + kMovieShowtimesButtonBottomMargin, 0);
}

- (void)setBackdropProgress:(CGFloat)progress {
  self.backdropProgressView.progress = progress;
}

- (void)updateContainerScrollViewMask {
  self.containerScrollView.layer.mask = [self createTopMaskWithSize:self.containerScrollView.contentSize startFadeAt:(self.delegate.topHeight - kMovieTopFadingHeightHalf) endAt:(self.delegate.topHeight + kMovieTopFadingHeightHalf) topColor:[UIColor clearColor] botColor:[UIColor whiteColor]];
}

- (void)updateShowtimesScrollViewContentSize {
  if (self.showtimesView.height <= self.showtimesScrollView.height) {
    self.showtimesScrollView.contentSize = CGSizeMake(self.showtimesScrollView.width, self.showtimesScrollView.height + self.infoView.top - self.delegate.topHeight);
    self.showtimesView.tableView.height = self.showtimesScrollView.height;
    self.showtimesView.height = self.showtimesScrollView.height;
    self.showtimesScrollView.contentInset = UIEdgeInsetsMake(self.showtimesScrollView.contentInset.top, 0, 0, 0);
  } else {
    self.showtimesScrollView.contentSize = CGSizeMake(self.showtimesScrollView.width, self.showtimesView.bottom);
    self.showtimesScrollView.contentInset = UIEdgeInsetsMake(self.showtimesScrollView.contentInset.top, 0, kMovieShowtimesButtonTopMargin + self.showtimesButton.height + kMovieShowtimesButtonBottomMargin, 0);
  }
}

- (void)infoTapped:(UITapGestureRecognizer *)gestureRecognizer {
  CGPoint tappedPoint = [gestureRecognizer locationInView:self.infoScrollView];

  if (tappedPoint.y < self.infoScrollView.height) {
    gestureRecognizer.cancelsTouchesInView = YES;
    if (!CGRectContainsPoint(self.infoView.frame, tappedPoint) && self.movie.trailerId) {
      self.playIconImageView.alpha = 0.7f;
      [self.delegate playTrailerForMovie:self.movie];
    } else {
      CGFloat ratio = self.infoScrollView.contentOffset.y < self.infoView.top - self.delegate.topHeight ? 1 : 0;
      [self.infoScrollView setContentOffset:CGPointMake(0, ratio * (self.infoView.top - self.delegate.topHeight)) animated:YES];
      [self.infoView expand:(ratio == 0)];
    }
  } else {
    gestureRecognizer.cancelsTouchesInView = NO;
  }
}

- (void)showtimesTapped:(UITapGestureRecognizer *)tapGestureRecognize {
  CGPoint tappedPoint = [tapGestureRecognize locationInView:self.showtimesScrollView];

  if (tappedPoint.y < self.showtimesScrollView.height) {
    if (!CGRectContainsPoint(self.showtimesView.frame, tappedPoint) && self.movie.trailerId) {
      self.playIconImageView.alpha = 0.7f;
      [self.delegate playTrailerForMovie:self.movie];
    }
  }
}

- (void)infoPressed:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
  CGPoint pressedPoint = [longPressGestureRecognizer locationInView:self.infoScrollView];

  if (!CGRectContainsPoint(self.infoView.frame, pressedPoint)) {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded) {
      [self.delegate playTrailerForMovie:self.movie];
    } else if (!self.playIconPressed) {
      self.playIconImageView.alpha = 0.7f;
      self.playIconPressed = YES;
    }
  } else if (self.playIconPressed) {
    self.playIconImageView.alpha = 0.6f;
    self.playIconPressed = NO;
  }
}

- (void)showtimesPressed:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
  CGPoint pressedPoint = [longPressGestureRecognizer locationInView:self.showtimesScrollView];

  if (!CGRectContainsPoint(self.showtimesView.frame, pressedPoint)) {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded) {
      [self.delegate playTrailerForMovie:self.movie];
    } else if (!self.playIconPressed) {
      self.playIconImageView.alpha = 0.7f;
      self.playIconPressed = YES;
    }
  } else if (self.playIconPressed) {
    self.playIconImageView.alpha = 0.6f;
    self.playIconPressed = NO;
  }
}

- (void)showtimesButtonTapped {
  [self.containerScrollView setContentOffset:CGPointMake(self.currentPageIndex == 0 ? self.showtimesScrollView.left : self.infoScrollView.left, 0) animated:YES];
}

#pragma mark Helpers

- (BOOL)isInLandscape {
  return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
}

- (CALayer *)createTopMaskWithSize:(CGSize)size startFadeAt:(CGFloat)top endAt:(CGFloat)bottom topColor:(UIColor *)topColor botColor:(UIColor *)botColor; {
  top /= size.height;
  bottom /= size.height;

  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  maskLayer.anchorPoint = CGPointZero;
  maskLayer.startPoint = CGPointMake(0.5f, 0);
  maskLayer.endPoint = CGPointMake(0.5f, 1);

  // An array of colors that dictatates the gradient(s)
  maskLayer.colors = @[(id)topColor.CGColor, (id)topColor.CGColor, (id)botColor.CGColor, (id)botColor.CGColor];
  maskLayer.locations = @[@0, @(top), @(bottom), @1];
  maskLayer.frame = CGRectMake(0, 0, size.width, size.height);

  return maskLayer;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView == self.containerScrollView) {
    CGFloat ratio = scrollView.contentOffset.x / self.infoScrollView.width;
    NSUInteger theatresCount = [[SEADataManager sharedInstance] localTheatresForMovie:self.movie].count;
    NSString *showtimesButtonText = [NSString stringWithFormat:@"%@ %@", @(theatresCount), [NSString getNumEnding:(NSInteger)theatresCount endings:@[@"кинотеатр", @"кинотеатра", @"кинотеатров"]]];
    [self.showtimesButton setTitle:(ratio < 0.5) ? showtimesButtonText : NSLocalizedString(@"К фильму", nil) forState:UIControlStateNormal];
    if (scrollView.contentOffset.x == self.showtimesScrollView.left) {
      self.currentPageIndex = 1;
      scrollView.userInteractionEnabled = YES;
      if (ABS(self.showtimesScrollView.contentOffset.y - self.infoView.top + self.delegate.topHeight) > 1) {
        self.showtimesScrollView.userInteractionEnabled = NO;
        [self.showtimesScrollView setContentOffset:CGPointMake(0, self.infoView.top - self.delegate.topHeight) animated:YES];
      }
      if (!self.infoView.isExpanded) {
        [self.infoView expand:NO];
      }
    } else if (scrollView.contentOffset.x == self.infoScrollView.left) {
      self.currentPageIndex = 0;
      scrollView.userInteractionEnabled = YES;
      if (self.infoScrollView.contentOffset.y != 0) {
        self.infoScrollView.userInteractionEnabled = NO;
        [self.infoScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
      }
      if (self.infoView.isExpanded) {
        [self.infoView expand:YES];
      }
    }
    [self.showtimesView hideVisiblePopTip];
  } else {
    if (scrollView == self.showtimesScrollView && ABS(scrollView.contentOffset.y - self.infoView.top + self.delegate.topHeight) <= 1) {
      scrollView.userInteractionEnabled = YES;
    } else if (scrollView == self.infoScrollView && scrollView.contentOffset.y == 0) {
      scrollView.userInteractionEnabled = YES;
    }
    // Translate ratio into height
    CGFloat ratio = scrollView.contentOffset.y / (self.infoView.top - self.delegate.topHeight);
    ratio = ratio < 0 ? 0 : ratio;
    ratio = ratio > 1 ? 1 : ratio;

    // Set alpha
    self.blurredBackdropImageView.alpha = ratio;
    self.backdropImageView.alpha = 1 - ratio;
    if (self.playIconImageView) {
      self.playIconImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1 - ratio), (1 - ratio));
      self.playIconImageView.centerY = (self.height - self.infoView.summaryHeight) / 2 * (1 - ratio);
    }
    // Set backdrop scroll
    if (![self isInLandscape]) {
      self.backdropScrollView.contentOffset = CGPointMake(0, ratio * kMovieBackdropMaxMovementVertical);
      self.blurredBackdropImageView.alpha *= 1 - ratio * 0.4f;
    } else {
      self.blurredBackdropImageView.alpha *= 0.6f;
      self.backdropImageView.alpha *= 0.6f;
    }

    if (scrollView == self.infoScrollView && self.currentPageIndex == 0) {
      self.showtimesScrollView.contentOffset = CGPointMake(0, MIN(self.infoScrollView.contentOffset.y, self.showtimesScrollView.contentSize.height - self.showtimesScrollView.height + self.showtimesScrollView.contentInset.bottom));
    } else if (scrollView == self.showtimesScrollView && self.currentPageIndex == 1) {
      self.infoScrollView.contentOffset = CGPointMake(0, MIN(self.showtimesScrollView.contentOffset.y, self.infoScrollView.contentSize.height - self.infoScrollView.height + self.infoScrollView.contentInset.bottom));
    }
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  if (scrollView == self.containerScrollView) {
    self.pagingScrollVelocity = velocity.x;
    if (velocity.x == 0) {
      if (targetContentOffset->x > self.infoScrollView.width / 2) {
        targetContentOffset->x = self.showtimesScrollView.left;
      } else {
        targetContentOffset->x = self.infoScrollView.left;
        [self.showtimesView hideVisiblePopTip];
      }
    }
  } else {
    CGPoint point = *targetContentOffset;
    CGFloat ratio = point.y / (self.infoView.top - self.delegate.topHeight);
    // It cannot be inbetween 0 to 1 so if it is >.5 it is one, otherwise 0
    if (ratio > 0 && ratio < 1) {
      if (velocity.y == 0) {
        ratio = ratio > 0.5f ? 1 : 0;
      } else if (velocity.y > 0) {
        ratio = ratio > 0.1f ? 1 : 0;
      } else {
        ratio = ratio > 0.9f ? 1 : 0;
      }
      targetContentOffset->y = ratio * (self.infoView.top - self.delegate.topHeight);
    }
    [self.infoView expand:(ratio < 1)];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (scrollView == self.showtimesScrollView) {
    [self.showtimesView hideVisiblePopTip];
  }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  if (scrollView == self.containerScrollView) {
    if (self.pagingScrollVelocity > 0) {
      scrollView.userInteractionEnabled = NO;
      [scrollView setContentOffset:CGPointMake(self.showtimesScrollView.left, 0) animated:YES];
    } else if (self.pagingScrollVelocity < 0) {
      scrollView.userInteractionEnabled = NO;
      [scrollView setContentOffset:CGPointMake(self.infoScrollView.left, 0) animated:YES];
    }
  }
}

@end
