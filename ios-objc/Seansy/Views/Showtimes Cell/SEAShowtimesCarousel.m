#import "SEAShowtimesCarousel.h"

#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"

UIEdgeInsets const kShowtimesCarouselCellPadding = {
  0, 15, 0, 15
};

@interface SEAShowtimesCarousel () <UIGestureRecognizerDelegate>

@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation SEAShowtimesCarousel

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

  UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
  flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kShowtimesCarouselHeight) collectionViewLayout:flowLayout];
  self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.scrollsToTop = NO;
  [self.collectionView registerClass:[SEAShowtimesItemCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAShowtimesItemCell class])];
  self.collectionView.backgroundColor = [UIColor clearColor];
  self.collectionView.showsHorizontalScrollIndicator = NO;
  [self.contentView addSubview:self.collectionView];

  self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
  self.panGestureRecognizer.delegate = self;
  self.panGestureRecognizer.cancelsTouchesInView = NO;
  [self addGestureRecognizer:self.panGestureRecognizer];

  return self;
}

#pragma mark Setters

- (void)setMovie:(SEAMovie *)movie {
  _movie = movie;
  self.showtimes = [self.movie showtimesForTheatreId:[@(self.theatre.id)stringValue]];
  [movie.backdrop getColorsWithCompletionBlock:^(NSDictionary *colors) {
    self.color = movie.backdrop.colors[kBackdropTextColorKey];
  }];
}

#pragma mark Public

- (void)refresh {
  CGFloat totalWidth = 0;
  CGPoint offset = CGPointZero;
  BOOL found = NO;

  for (SEAShowtime *showtime in self.showtimes) {
    totalWidth += [self sizeForShowtime:showtime].width + (showtime != self.showtimes[0] ? 5 : 0);
    if (!found) {
      if ([showtime hasPassed]) {
        offset.x += [self sizeForShowtime:showtime].width + 5;
      } else {
        found = YES;
      }
    }
  }

  if (totalWidth < self.width - kShowtimesCellCollectionViewPadding.left - kShowtimesCellCollectionViewPadding.right) {
    offset = CGPointZero;
  } else if (offset.x > totalWidth - self.width + kShowtimesCellCollectionViewPadding.left + kShowtimesCellCollectionViewPadding.right || !found) {
    offset.x = totalWidth - self.width + kShowtimesCellCollectionViewPadding.left + kShowtimesCellCollectionViewPadding.right;
  }

  self.collectionView.contentOffset = offset;
  [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];

  return [self sizeForShowtime:showtime];
}

- (CGSize)sizeForShowtime:(SEAShowtime *)showtime {
  CGFloat timeStringWidth = [[showtime timeString] boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : [UIFont timeFontWithSize:[UIFont largeTextFontSize]] } context:nil].size.width;
  CGFloat formatStringWidth = 0;

  if (showtime.format) {
    formatStringWidth = [[showtime formatString] boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont smallTextFontSize]] } context:nil].size.width;
  }

  return CGSizeMake(MAX(timeStringWidth, formatStringWidth) + kShowtimesCarouselCellPadding.left + kShowtimesCarouselCellPadding.right, self.collectionView.height - kShowtimesCellCollectionViewPadding.top - kShowtimesCellCollectionViewPadding.bottom);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAShowtimesItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAShowtimesItemCell class]) forIndexPath:indexPath];
  SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];

  cell.label.attributedText = [showtime attributedSummaryString];
  UIColor *startColor = [[UIColor whiteColor] blendWithColor:self.color alpha:0.4f];
  UIColor *endColor = self.color;
  if (self.showtimes.count <= 5) {
    endColor = [[UIColor whiteColor] blendWithColor:self.color alpha:0.8f];
  }

  cell.color = [startColor blendWithColor:endColor alpha:(CGFloat)indexPath.row / self.showtimes.count];
  if ([showtime hasPassed]) {
    cell.alpha = kDisabledAlpha;
  }

  cell.label.frame = cell.bounds;
  [self.cells addObject:cell];
  return cell;
}

#pragma mark Gesture recognizers

- (void)didPan:(UIPanGestureRecognizer *)gestureRecognizer {
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer == self.panGestureRecognizer) {
    CGPoint velocity = [self.panGestureRecognizer velocityInView:self];
    BOOL isHorizontal = fabs(velocity.x) > fabs(velocity.y);
    return isHorizontal;
  }
  return YES;
}

@end
