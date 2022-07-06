#import "SEAMovieDetailsInfoView.h"

#import "AYMacros.h"
#import "SEAConstants.h"
#import "SEAPersonsCarouselCell.h"
#import "SEAReviewsCarouselCell.h"
#import "SEAStill.h"
#import "SEAStillsCarouselCell.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <SDWebImage/UIImageView+WebCache.h>

static UIEdgeInsets const kMovieDetailsInfoViewPadding = {
  10, 10, 10, 10
};
static CGFloat const kMovieDetailsInfoViewLabelsVerticalSpacing = 10;
static CGFloat const kMovieDetailsInfoViewLabelsHorizontalSpacing = 10;
static CGFloat const kMovieDetailsInfoViewRatingIconMargin = 6;
static CGFloat const kMovieDetailsInfoViewRatingsSpacing = 10;
static CGFloat const kMovieDetailsInfoViewStillsCarouselHeight = 100;

@interface TopAlignedCollectionViewFlowLayout : UICollectionViewFlowLayout
@end

@implementation TopAlignedCollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
  NSArray *attributesToReturn = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
  for (UICollectionViewLayoutAttributes *attributes in attributesToReturn) {
    if (nil == attributes.representedElementKind) {
      NSIndexPath *indexPath = attributes.indexPath;
      attributes.frame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
    }
  }
  return attributesToReturn;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewLayoutAttributes *currentItemAttributes = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];
  CGRect currentItemAttributesFrame = currentItemAttributes.frame;
  currentItemAttributesFrame.origin.y = 0;
  currentItemAttributes.frame = currentItemAttributesFrame;
  return currentItemAttributes;
}

@end

@interface SEAMovieDetailsInfoView () <UICollectionViewDataSource, UICollectionViewDelegate, NYTPhotosViewControllerDelegate>

@property (nonatomic) NSMutableArray *labels;
@property (nonatomic) UICollectionView *castCarousel;
@property (nonatomic) UICollectionView *reviewsCarousel;
@property (nonatomic) UICollectionView *stillsCarousel;
@property (nonatomic) UILabel *ageLabel;
@property (nonatomic) UILabel *castLabel;
@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UILabel *directorLabel;
@property (nonatomic) UILabel *genresLabel;
@property (nonatomic) UILabel *originalTitleLabel;
@property (nonatomic) UILabel *reviewsLabel;
@property (nonatomic) UILabel *runtimeLabel;
@property (nonatomic) UILabel *scriptLabel;
@property (nonatomic) UILabel *stillsLabel;
@property (nonatomic) UILabel *synopsisLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *cast;
@property (nonatomic) UIScrollView *ratings;
@property (nonatomic) UIView *reviews;
@property (nonatomic) UIView *stills;
@property (weak, nonatomic) SEAMovie *movie;
@property (nonatomic) UILabel *bonusSceneLabel;

@end

@implementation SEAMovieDetailsInfoView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame movie:(SEAMovie *)movie {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.movie = movie;
  [self setUpViews];

  return self;
}

#pragma mark Setters

- (void)setDelegate:(id<SEAMovieDetailsInfoViewDelegate>)delegate {
  _delegate = delegate;
  CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds) - self.delegate.topHeight;
  if (self.fullHeight < screenHeight) {
    self.fullHeight = screenHeight + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
  self.height = self.fullHeight;
}

#pragma mark Private

- (void)setUpViews {
  [self setUpPoster];

  self.labels = [NSMutableArray array];
  [self setUpTitleLabel];
  [self setUpOriginalTitleLabel];
  CGFloat centerOffset = (self.poster.height - (self.originalTitleLabel.bottom - self.titleLabel.top)) / 2 - 5;
  self.titleLabel.top += centerOffset;
  self.originalTitleLabel.top += centerOffset;

  self.summaryHeight = (self.poster.bottom > self.originalTitleLabel.bottom ? self.poster.bottom : self.originalTitleLabel.bottom) + kMovieDetailsInfoViewLabelsVerticalSpacing;

  [self setUpDateLabel];
  [self setUpRatings];
  [self setUpGenresLabel];
  [self setUpAgeAndRuntimeLabels];

  self.fullHeight = self.summaryHeight;

  [self setUpSynopsisLabel];
  [self setUpStillsView];
  [self setUpReviewsView];
  [self setUpDirectorLabel];
  [self setUpScriptLabel];
  [self setUpCastView];
  [self setUpBonusSceneLabel];

  for (UILabel *label in self.labels) {
    label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5f];
    label.shadowOffset = CGSizeMake(1, 1);
  }

  self.height = self.fullHeight;
}

- (void)setUpPoster {
  self.poster = [[UIImageView alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, 0, 70, 70 / 0.7f)];
  [[self.movie.poster getImage] subscribeNext:^(RACTuple *tuple) {
    self.poster.image = [tuple first];
  } completed:^{
    if (![UIImagePNGRepresentation(self.poster.image) isEqual:UIImagePNGRepresentation([UIImage imageNamed:@"PosterPlaceholder"])]) {
      UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnPoster:)];
      [self.poster addGestureRecognizer:tapGestureRecognizer];
    }
  }];
  self.poster.contentMode = UIViewContentModeScaleToFill;
  self.poster.clipsToBounds = YES;
  self.poster.userInteractionEnabled = YES;
  [self addSubview:self.poster];
}

- (void)didTapOnPoster:(UITapGestureRecognizer *)gestureRecognizer {
  NYTPhotosViewController *stillsViewController = [[NYTPhotosViewController alloc] initWithPhotos:@[self.movie.poster]];
  stillsViewController.delegate = self;
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  [self.delegate presentViewController:stillsViewController];
}

- (void)setUpTitleLabel {
  self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.poster.right + kMovieDetailsInfoViewLabelsHorizontalSpacing, 0, self.width - self.poster.right - kMovieDetailsInfoViewLabelsHorizontalSpacing - kMovieDetailsInfoViewPadding.right, 0)];
  self.titleLabel.text = self.movie.title;
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.font = [UIFont lightFontWithSize:[UIFont movieTitleFontSize]];
  [self.titleLabel adjustFontSizeWithMaxLines:(self.movie.title.length > 15 ? 2 : 1) fontFloor:[UIFont largeTextFontSize]];
  [self.labels addObject:self.titleLabel];
  [self addSubview:self.titleLabel];
}

- (void)setUpOriginalTitleLabel {
  self.originalTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.titleLabel.left, self.titleLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing, self.titleLabel.width, 0)];
  if (self.movie.originalTitle.length > 0 && ![self.movie.originalTitle isEqualToString:self.movie.title]) {
    self.originalTitleLabel.text = [NSString stringWithFormat:@"%@ (%@)", self.movie.originalTitle, @(self.movie.year)];
    self.originalTitleLabel.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
  } else if (self.movie.year > 0) {
    self.originalTitleLabel.text = [NSString stringWithFormat:@"%@", @(self.movie.year)];
    self.originalTitleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  }
  self.originalTitleLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
  self.originalTitleLabel.numberOfLines = 0;
  [self.originalTitleLabel setFrameToFitWithHeightLimit:0];
  [self.labels addObject:self.originalTitleLabel];
  [self addSubview:self.originalTitleLabel];
}

- (void)setUpDateLabel {
  if (self.movie.date) {
    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.summaryHeight, 0, 0)];
    self.dateLabel.text = [self.movie longDateString];
    self.dateLabel.textColor = [UIColor whiteColor];
    self.dateLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    self.dateLabel.textAlignment = NSTextAlignmentCenter;
    self.dateLabel.layer.borderWidth = 1;
    self.dateLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.dateLabel.layer.cornerRadius = 5;
    [self.dateLabel sizeToFit];
    self.dateLabel.width += 10;
    self.dateLabel.height += 10;
    [self.labels addObject:self.dateLabel];
    [self addSubview:self.dateLabel];
    self.summaryHeight = self.dateLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpRatings {
  self.ratings = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.summaryHeight, self.width, 20)];
  self.ratings.contentInset = UIEdgeInsetsMake(0, kMovieDetailsInfoViewPadding.left, 0, kMovieDetailsInfoViewPadding.right);
  self.ratings.showsHorizontalScrollIndicator = NO;
  if (IS_IPHONE_6P) {
    self.ratings.height += 10;
  }

  CGFloat horizontalOffset = 0;
  for (SEARatingSource i = 0; i < self.movie.ratings.count; i++) {
    if ([self.movie.ratings[i] integerValue] > 0) {
      NSString *imageName;
      switch (i) {
        case SEARatingSourceKinopoisk:
          imageName = @"Kinopoisk";
          break;
        case SEARatingSourceIMDB:
          imageName = @"Imdb";
          break;
        case SEARatingSourceRTCritics:
          if ([self.movie.ratings[i] integerValue] < 60) {
            imageName = @"RottenTomato";
          } else {
            imageName = @"FreshTomato";
          }
          break;
        case SEARatingSourceRTAudience:
          if ([self.movie.ratings[i] integerValue] < 60) {
            imageName = @"FallenPopcorn";
          } else {
            imageName = @"StandingPopcorn";
          }
          break;
        default:
          break;
      }
      UIImage *ratingIcon = [UIImage imageNamed:imageName];
      CGFloat ratingIconWidth = (ratingIcon.size.width / ratingIcon.size.height) * self.ratings.height;
      UIImageView *ratingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, 0, ratingIconWidth, self.ratings.height)];
      [ratingImageView setImage:ratingIcon];
      horizontalOffset += ratingImageView.width + kMovieDetailsInfoViewRatingIconMargin;

      UILabel *ratingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
      if (i == SEARatingSourceKinopoisk) {
        ratingLabel.attributedText = [self.movie kpRatingString];
      } else if (i == SEARatingSourceIMDB) {
        ratingLabel.attributedText = [self.movie imdbRatingString];
      } else {
        ratingLabel.textColor = [UIColor whiteColor];
        ratingLabel.font = [UIFont regularFontWithSize:[UIFont ratingFontSize]];
        ratingLabel.text = [NSString stringWithFormat:@"%@%%", self.movie.ratings[i]];
      }
      ratingLabel.frame = CGRectMake(horizontalOffset, 0, [ratingLabel.text sizeWithAttributes:@{ NSFontAttributeName : ratingLabel.font }].width, self.ratings.height);
      self.ratings.contentSize = CGSizeMake(ratingLabel.right, self.ratings.height);
      horizontalOffset += ratingLabel.width + kMovieDetailsInfoViewRatingsSpacing;

      [self.ratings addSubview:ratingImageView];
      [self.ratings addSubview:ratingLabel];
      [self.labels addObject:ratingLabel];
    }
  }

  if (horizontalOffset != 0) {
    [self addSubview:self.ratings];
    self.summaryHeight = self.ratings.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpGenresLabel {
  if (self.movie.genre) {
    self.genresLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.summaryHeight, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.genresLabel.text = [self.movie genreString];
    self.genresLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
    self.genresLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    self.genresLabel.numberOfLines = 0;
    [self.genresLabel setFrameToFitWithHeightLimit:60];
    [self.labels addObject:self.genresLabel];
    [self addSubview:self.genresLabel];
    self.summaryHeight = self.genresLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpAgeAndRuntimeLabels {
  if (self.movie.age >= 0 || self.movie.runtime > 0) {
    if (self.movie.age >= 0) {
      self.ageLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.summaryHeight, 0, 0) ];
      self.ageLabel.text = [NSString stringWithFormat:@"%@+", @(self.movie.age)];
      self.ageLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
      self.ageLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
      [self.ageLabel sizeToFit];
      self.ageLabel.width += 8;
      self.ageLabel.height += 4;
      [self.ageLabel setTextAlignment:NSTextAlignmentCenter];
      [self.ageLabel.layer setBorderWidth:1];
      [self.ageLabel.layer setBorderColor:[[self.movie.backdrop.colors objectForKey:kBackdropTextColorKey] CGColor]];
      [self.ageLabel.layer setShadowOffset:CGSizeMake(1, 1)];
      [self.ageLabel.layer setShadowRadius:0];
      [self.ageLabel.layer setShadowColor:[UIColor blackColor].CGColor];
      [self.ageLabel.layer setShadowOpacity:0.5];
      [self addSubview:self.ageLabel];
    }
    if (self.movie.runtime > 0) {
      self.runtimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.summaryHeight, 0, 0)];
      self.runtimeLabel.text = [self.movie runtimeString];
      self.runtimeLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
      self.runtimeLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
      [self.runtimeLabel sizeToFit];
      if (self.ageLabel) {
        self.runtimeLabel.left = self.ageLabel.right + kMovieDetailsInfoViewLabelsHorizontalSpacing;
        self.runtimeLabel.centerY = self.ageLabel.centerY;
      }
      self.summaryHeight = self.runtimeLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing;
      [self.labels addObject:self.runtimeLabel];
      [self addSubview:self.runtimeLabel];
    } else {
      self.summaryHeight = self.ageLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing;;
    }
  }
}

- (void)setUpSynopsisLabel {
  if (self.movie.synopsis) {
    self.synopsisLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.summaryHeight, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.synopsisLabel.text = self.movie.synopsis;
    self.synopsisLabel.textColor = [UIColor whiteColor];
    self.synopsisLabel.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
    self.synopsisLabel.numberOfLines = 0;
    self.synopsisLabel.contentMode = UIViewContentModeTopLeft;
    [self.synopsisLabel setFrameToFitWithHeightLimit:100];
    self.summaryHeight = self.synopsisLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing;
    [self.labels addObject:self.synopsisLabel];
    [self addSubview:self.synopsisLabel];
    self.fullHeight += [self.synopsisLabel sizeToFitWithHeightLimit:0].height + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpStillsView {
  if (self.movie.stills) {
    self.stills = [[UIView alloc] initWithFrame:CGRectMake(0, self.fullHeight, self.width, 0)];
    self.stills.alpha = 0;

    self.stillsLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, 0, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.stillsLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
    self.stillsLabel.font = [UIFont boldFontWithSize:[UIFont mediumTextFontSize]];
    self.stillsLabel.text = NSLocalizedString(@"Кадры из фильма:", nil);
    [self.stillsLabel setFrameToFitWithHeightLimit:0];
    [self.labels addObject:self.stillsLabel];
    [self.stills addSubview:self.stillsLabel];

    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.stillsCarousel = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.stillsLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing, self.width, kMovieDetailsInfoViewStillsCarouselHeight) collectionViewLayout:flowLayout];
    self.stillsCarousel.dataSource = self;
    self.stillsCarousel.delegate = self;
    [self.stillsCarousel registerClass:[SEAStillsCarouselCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAStillsCarouselCell class])];
    self.stillsCarousel.backgroundColor = [UIColor clearColor];
    self.stillsCarousel.showsHorizontalScrollIndicator = NO;
    self.stills.height = self.stillsCarousel.bottom;
    [self.stills addSubview:self.stillsCarousel];

    [self addSubview:self.stills];
    self.fullHeight += self.stills.height + kMovieDetailsInfoViewLabelsVerticalSpacing;

    NSMutableArray *signals = [NSMutableArray new];
    [self.movie.stills enumerateObjectsUsingBlock:^(SEAStill *still, NSUInteger idx, BOOL *stop) {
      [signals addObject:[still getSize]];
    }];
    [[RACSignal merge:signals] subscribeNext:^(NSValue *size) {
      [self.stillsCarousel.collectionViewLayout invalidateLayout];
    }];
  }
}

- (void)setUpReviewsView {
  if (self.movie.reviews) {
    self.reviews = [[UIView alloc] initWithFrame:CGRectMake(0, self.fullHeight, self.width, 0)];
    self.reviews.alpha = 0;

    self.reviewsLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, 0, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.reviewsLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
    self.reviewsLabel.font = [UIFont boldFontWithSize:[UIFont mediumTextFontSize]];
    self.reviewsLabel.text = NSLocalizedString(@"Рецензии:", nil);
    [self.reviewsLabel setFrameToFitWithHeightLimit:0];
    [self.labels addObject:self.reviewsLabel];
    [self.reviews addSubview:self.reviewsLabel];

    NSMutableArray *reviewsHeights = [NSMutableArray new];
    for (NSDictionary *review in self.movie.reviews) {
      [reviewsHeights addObject:@([SEAReviewsCarouselCell sizeForText:review[@"text"]].height)];
    }
    TopAlignedCollectionViewFlowLayout *flowLayout = [TopAlignedCollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.reviewsCarousel = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.reviewsLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing, self.width, MIN(150, (CGFloat)[[reviewsHeights valueForKeyPath:@"@min.intValue"] doubleValue])) collectionViewLayout:flowLayout];
    self.reviewsCarousel.dataSource = self;
    self.reviewsCarousel.delegate = self;
    [self.reviewsCarousel registerClass:[SEAReviewsCarouselCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAReviewsCarouselCell class])];
    self.reviewsCarousel.backgroundColor = [UIColor clearColor];
    self.reviewsCarousel.showsHorizontalScrollIndicator = NO;
    self.reviews.height = self.reviewsCarousel.bottom;
    [self.reviews addSubview:self.reviewsCarousel];

    [self addSubview:self.reviews];
    self.fullHeight += self.reviews.height + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpDirectorLabel {
  if (self.movie.director) {
    self.directorLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.fullHeight, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.directorLabel.attributedText = self.movie.directorString;
    self.directorLabel.numberOfLines = 0;
    [self.directorLabel setFrameToFitWithHeightLimit:0];
    self.directorLabel.alpha = 0;
    [self.labels addObject:self.directorLabel];
    [self addSubview:self.directorLabel];
    self.fullHeight += self.directorLabel.height + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpScriptLabel {
  if (self.movie.script) {
    self.scriptLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.fullHeight, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.scriptLabel.attributedText = self.movie.scriptString;
    self.scriptLabel.numberOfLines = 0;
    [self.scriptLabel setFrameToFitWithHeightLimit:0];
    self.scriptLabel.alpha = 0;
    [self.labels addObject:self.scriptLabel];
    [self addSubview:self.scriptLabel];
    self.fullHeight += self.scriptLabel.height + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpCastView {
  if (self.movie.cast) {
    self.cast = [[UIView alloc] initWithFrame:CGRectMake(0, self.fullHeight, self.width, 0)];
    self.cast.alpha = 0;

    self.castLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, 0, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.castLabel.textColor = self.movie.backdrop.colors[kBackdropTextColorKey];
    self.castLabel.font = [UIFont boldFontWithSize:[UIFont mediumTextFontSize]];
    [self.labels addObject:self.castLabel];
    if ([self.movie.cast[0] isKindOfClass:[NSDictionary class]]) {
      self.castLabel.text = NSLocalizedString(@"В главных ролях:", nil);
      [self.castLabel setFrameToFitWithHeightLimit:0];
      UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
      flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
      self.castCarousel = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.castLabel.bottom + kMovieDetailsInfoViewLabelsVerticalSpacing, self.width, [self personsCarouselCellSize].height) collectionViewLayout:flowLayout];
      self.castCarousel.dataSource = self;
      self.castCarousel.delegate = self;
      [self.castCarousel registerClass:[SEAPersonsCarouselCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAPersonsCarouselCell class])];
      self.castCarousel.backgroundColor = [UIColor clearColor];
      self.castCarousel.showsHorizontalScrollIndicator = NO;
      self.cast.height = self.castCarousel.bottom;
    } else {
      self.castLabel.attributedText = self.movie.castString;
      self.castLabel.numberOfLines = 0;
      [self.castLabel setFrameToFitWithHeightLimit:0];
      self.cast.height = self.castLabel.bottom;
    }
    [self.cast addSubview:self.castLabel];
    [self.cast addSubview:self.castCarousel];
    [self addSubview:self.cast];
    self.fullHeight += self.cast.height + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

- (void)setUpBonusSceneLabel {
  if (self.movie.bonusSceneString) {
    self.bonusSceneLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMovieDetailsInfoViewPadding.left, self.fullHeight, self.width - kMovieDetailsInfoViewPadding.left - kMovieDetailsInfoViewPadding.right, 0)];
    self.bonusSceneLabel.text = [@"⚫︎ " stringByAppendingString:self.movie.bonusSceneString];
    self.bonusSceneLabel.numberOfLines = 0;
    self.bonusSceneLabel.font = [UIFont boldFontWithSize:[UIFont mediumTextFontSize]];
    [self.bonusSceneLabel setFrameToFitWithHeightLimit:0];
    self.bonusSceneLabel.alpha = 0;
    [self.labels addObject:self.bonusSceneLabel];
    [self addSubview:self.bonusSceneLabel];
    self.fullHeight += self.bonusSceneLabel.height + kMovieDetailsInfoViewLabelsVerticalSpacing;
  }
}

#pragma mark Public

- (void)updateLabelColors:(NSDictionary *)colors {
  self.originalTitleLabel.textColor = colors[kBackdropTextColorKey];
  self.genresLabel.textColor = colors[kBackdropTextColorKey];
  self.ageLabel.textColor = colors[kBackdropTextColorKey];
  self.ageLabel.layer.borderColor = [colors[kBackdropTextColorKey] CGColor];
  self.runtimeLabel.textColor = colors[kBackdropTextColorKey];
  self.directorLabel.attributedText = self.movie.directorString;
  self.scriptLabel.attributedText = self.movie.scriptString;
  if ([self.movie.cast[0] isKindOfClass:[NSDictionary class]]) {
    self.castLabel.textColor = colors[kBackdropTextColorKey];
  } else {
    self.castLabel.attributedText = self.movie.castString;
  }
  self.stillsLabel.textColor = colors[kBackdropTextColorKey];
  self.reviewsLabel.textColor = colors[kBackdropTextColorKey];
  self.bonusSceneLabel.textColor = colors[kBackdropTextColorKey];
}

- (void)expand:(BOOL)revert {
  self.expanded = !revert;
  CGFloat newHeight = [self.synopsisLabel sizeToFitWithHeightLimit:(revert) ? 100 : 0].height;
  CGFloat alpha = (revert) ? 0 : 1;
  [UIView animateWithDuration:0.4f animations:^{
    self.directorLabel.alpha = alpha;
    self.scriptLabel.alpha = alpha;
    self.cast.alpha = alpha;
    self.stills.alpha = alpha;
    self.reviews.alpha = alpha;
    self.bonusSceneLabel.alpha = alpha;
    self.synopsisLabel.height = newHeight;
  }];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (collectionView == self.castCarousel) {
    return (NSInteger)self.movie.cast.count;
  } else if (collectionView == self.stillsCarousel) {
    return (NSInteger)self.movie.stills.count;
  } else if (collectionView == self.reviewsCarousel) {
    return (NSInteger)self.movie.reviews.count;
  } else {
    return 0;
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
  return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  return 2;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.castCarousel) {
    return [self personsCarouselCellSize];
  } else if (collectionView == self.stillsCarousel) {
    CGSize size = [(SEAStill *)self.movie.stills[(NSUInteger)indexPath.row] size];
    if (CGSizeEqualToSize(size, CGSizeZero)) {
      return CGSizeMake(kMovieDetailsInfoViewStillsCarouselHeight, kMovieDetailsInfoViewStillsCarouselHeight);
    }
    return CGSizeMake(size.width / size.height * kMovieDetailsInfoViewStillsCarouselHeight, kMovieDetailsInfoViewStillsCarouselHeight);
  } else if (collectionView == self.reviewsCarousel) {
    return CGSizeMake(kReviewsCarouselCellWidth, collectionView.height);
  } else {
    return CGSizeZero;
  }
}

- (CGSize)personsCarouselCellSize {
  CGFloat width;
  if (self.width <= 414) {
    width = self.width / 3 - 4 / 3;
  } else {
    width = self.width / 5 - 8 / 5;
  }
  CGFloat height = width / 0.63f;
  return CGSizeMake(width, height + kCarouselNameOffset);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.castCarousel) {
    SEAPersonsCarouselCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAPersonsCarouselCell class]) forIndexPath:indexPath];
    cell.loader.frame = CGRectMake(0, 0, [self personsCarouselCellSize].width, [self personsCarouselCellSize].height - kCarouselNameOffset);
    [cell.loader startAnimating];
    NSDictionary *dictionary = self.movie.cast[(NSUInteger)indexPath.row];
    NSString *name = [dictionary objectForKey:@"name"];
    NSURL *photoUrl = [NSURL URLWithString:[dictionary objectForKey:@"photo"]];
    if ([photoUrl absoluteString].length > 0) {
      [cell.photo sd_setImageWithURL:photoUrl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (cacheType == SDImageCacheTypeNone) {
          cell.photo.alpha = 0;
          [UIView animateWithDuration:0.3 animations:^{
            cell.photo.alpha = 1;
            [cell.loader stopAnimating];
          }];
        } else {
          [cell.loader stopAnimating];
        }
      }];
    } else {
      cell.photo.image = nil;
      cell.placeholderLabel.text = [self nameInitials:name];
      cell.placeholderLabel.hidden = NO;
      [cell.loader stopAnimating];
    }
    cell.photo.frame = cell.loader.frame;
    cell.placeholderLabel.frame = cell.loader.frame;
    cell.nameLabel.frame = CGRectMake(5, [self personsCarouselCellSize].height - kCarouselNameOffset + 5, [self personsCarouselCellSize].width - 10, kCarouselNameOffset - 5);
    cell.nameLabel.text = name;
    [cell.nameLabel setFrameToFitWithHeightLimit:kCarouselNameOffset - 10];
    return cell;
  } else if (collectionView == self.stillsCarousel) {
    SEAStillsCarouselCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAStillsCarouselCell class]) forIndexPath:indexPath];
    [cell.loader startAnimating];
    SEAStill *still = (SEAStill *)self.movie.stills[(NSUInteger)indexPath.row];
    [[still getImage] subscribeNext:^(RACTuple *tuple) {
      RACTupleUnpack(UIImage * image, NSNumber * fromCache) = tuple;
      cell.photo.image = image;
      if (![fromCache boolValue]) {
        cell.photo.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
          cell.photo.alpha = 1;
          [cell.loader stopAnimating];
        }];
      } else {
        [cell.loader stopAnimating];
      }
    }];
    return cell;
  } else if (collectionView == self.reviewsCarousel) {
    SEAReviewsCarouselCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAReviewsCarouselCell class]) forIndexPath:indexPath];
    cell.review = self.movie.reviews[(NSUInteger)indexPath.row];
    return cell;
  } else {
    return nil;
  }
}

- (NSString *)nameInitials:(NSString *)name {
  NSMutableString *initials = [NSMutableString string];
  NSArray *words = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  for (NSString *word in words) {
    if ([word length] > 0) {
      NSString *firstLetter = [word substringWithRange:[word rangeOfComposedCharacterSequenceAtIndex:0]];
      [initials appendString:[firstLetter uppercaseString]];
    }
  }
  return initials;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.stillsCarousel) {
    NYTPhotosViewController *stillsViewController = [[NYTPhotosViewController alloc] initWithPhotos:self.movie.stills initialPhoto:(SEAStill *)self.movie.stills[(NSUInteger)indexPath.row]];
    stillsViewController.delegate = self;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.delegate presentViewController:stillsViewController];
    for (SEAStill *still in self.movie.stills) {
      if (!still.image) {
        [[still getImage] subscribeNext:^(RACTuple *tuple) {
          [stillsViewController updateImageForPhoto:still];
        }];
      }
    }
  }
}

#pragma mark NYTPhotosViewControllerDelegate

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id <NYTPhoto>)photo {
  if ([photo isKindOfClass:[SEAPoster class]]) {
    return self.poster;
  }
  return [self.stillsCarousel cellForItemAtIndexPath:[NSIndexPath indexPathForRow:(NSInteger)[self.movie.stills indexOfObject:photo] inSection:0]];
}

- (void)photosViewControllerDidDismiss:(NYTPhotosViewController *)photosViewController {
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

@end
