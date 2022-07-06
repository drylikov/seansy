#import "SEAShowtimesList.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAShowtime.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <UICollectionViewLeftAlignedLayout/UICollectionViewLeftAlignedLayout.h>

UIEdgeInsets const kShowtimesListCellPadding = {
  7, 10, 7, 10
};

@interface SEAShowtimesList ()

@property (nonatomic) UIView *collectionViewWrapper;

@end

@implementation SEAShowtimesList

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.backdrop = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kShowtimesListCellHeight)];
  self.backdrop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.backdrop.contentMode = UIViewContentModeScaleAspectFill;
  self.backdrop.clipsToBounds = YES;
  [self.contentView addSubview:self.backdrop];

  self.poster = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kShowtimesListCellHeight * 0.7f, kShowtimesListCellHeight)];
  self.poster.contentMode = UIViewContentModeScaleToFill;
  self.poster.clipsToBounds = YES;
  self.poster.userInteractionEnabled = YES;
  [self.contentView addSubview:self.poster];

  self.collectionViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(self.poster.right, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - self.poster.right, kShowtimesListCellHeight)];
  self.collectionViewWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  UICollectionViewLeftAlignedLayout *flowLayout = [UICollectionViewLeftAlignedLayout new];
  flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
  self.collectionView = [[UICollectionView alloc] initWithFrame:self.collectionViewWrapper.bounds collectionViewLayout:flowLayout];
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.scrollsToTop = NO;
  [self.collectionView registerClass:[SEAShowtimesItemCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAShowtimesItemCell class])];
  self.collectionView.backgroundColor = [UIColor clearColor];
  self.collectionView.showsVerticalScrollIndicator = NO;
  [self.collectionViewWrapper addSubview:self.collectionView];
  [self.contentView addSubview:self.collectionViewWrapper];

  UITapGestureRecognizer *posterTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(posterTapped:)];
  [self.poster addGestureRecognizer:posterTapGestureRecognizer];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.backdrop.image = nil;
  self.poster.image = nil;
}

- (void)layoutSubviews {
  self.collectionView.frame = self.collectionViewWrapper.bounds;
  [self refresh];
  [self.collectionView layoutIfNeeded];
  if (self.collectionView.contentSize.height > self.collectionView.height) {
    self.collectionViewWrapper.layer.mask = [self createBottomMaskWithSize:self.collectionViewWrapper.frame.size startFadeAt:self.collectionView.height - 20 endAt:self.collectionView.height topColor:[UIColor whiteColor] botColor:[UIColor clearColor]];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 20, 0);
  }
}

#pragma mark Setters

- (void)setMovie:(SEAMovie *)movie {
  _movie = movie;
  [movie.backdrop getFilteredImageWithProgressBlock:nil completionBlock:^(UIImage *filteredImage, UIImage *originalImage, BOOL fromCache) {
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
      self.color = movie.backdrop.colors[kBackdropTextColorKey];
    }];
  }];
  [self.poster sd_setImageWithURL:movie.poster.url placeholderImage:[UIImage imageNamed:@"PosterPlaceholder"]
   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    if (cacheType == SDImageCacheTypeNone) {
      self.poster.alpha = 0;
      [UIView animateWithDuration:0.3f animations:^{
        self.poster.alpha = 1;
      }];
    }
  }];
}

#pragma mark Public

- (void)refresh {
  [self.collectionView.collectionViewLayout invalidateLayout];
  [self.collectionView reloadData];
}

#pragma mark Private

- (void)posterTapped:(UILongPressGestureRecognizer *)tapGestureRecognizer {
  if (tapGestureRecognizer.state != UIGestureRecognizerStateEnded) {
    return;
  } else if (self.delegate) {
    [self.delegate cellPosterTapped:self];
  }
}

- (CALayer *)createBottomMaskWithSize:(CGSize)size startFadeAt:(CGFloat)top endAt:(CGFloat)bottom topColor:(UIColor *)topColor botColor:(UIColor *)botColor; {
  top /= size.height;
  bottom /= size.height;

  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  maskLayer.anchorPoint = CGPointZero;
  maskLayer.startPoint = CGPointMake(0.5f, 0);
  maskLayer.endPoint = CGPointMake(0.5f, 1);

  maskLayer.colors = @[(id)topColor.CGColor, (id)topColor.CGColor, (id)botColor.CGColor, (id)botColor.CGColor];
  maskLayer.locations = @[@0, @(top), @(bottom), @1];
  maskLayer.frame = CGRectMake(0, 0, size.width, size.height);

  return maskLayer;
}

#pragma mark UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];
  return [self sizeForShowtime:showtime];
}

- (CGSize)sizeForShowtime:(SEAShowtime *)showtime {
  NSAttributedString *showtimeText = [showtime attributedSummaryInlineString];
  CGSize showtimeTextStringSize = [showtimeText boundingRectWithSize:CGSizeMake(self.collectionView.width - kShowtimesCellCollectionViewPadding.left - kShowtimesCellCollectionViewPadding.right - kShowtimesListCellPadding.left - kShowtimesListCellPadding.right, 0) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
  return CGSizeMake(showtimeTextStringSize.width + kShowtimesListCellPadding.left + kShowtimesListCellPadding.right, showtimeTextStringSize.height + kShowtimesListCellPadding.top + kShowtimesListCellPadding.bottom);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAShowtimesItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAShowtimesItemCell class]) forIndexPath:indexPath];
  cell.label.frame = CGRectMake(kShowtimesListCellPadding.left, 0, cell.width - kShowtimesListCellPadding.left - kShowtimesListCellPadding.right, cell.height);
  SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];
  cell.label.attributedText = [showtime attributedSummaryInlineString];
  UIColor *startColor = [[UIColor whiteColor] blendWithColor:self.color alpha:0.4f];
  UIColor *endColor = self.color;
  if (self.showtimes.count <= 5) {
    endColor = [[UIColor whiteColor] blendWithColor:self.color alpha:0.8f];
  }

  cell.color = [startColor blendWithColor:endColor alpha:(CGFloat)indexPath.row / self.showtimes.count];
  if ([showtime hasPassed]) {
    cell.alpha = kDisabledAlpha;
  }

  [self.cells addObject:cell];
  return cell;
}

#pragma mark SEAPosterViewDelegate

- (void)restorePoster {
  self.poster.alpha = 1;
}

@end
