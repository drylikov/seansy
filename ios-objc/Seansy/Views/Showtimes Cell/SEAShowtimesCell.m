#import "SEAShowtimesCell.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UIView+AYUtils.h"

UIEdgeInsets const kShowtimesCellCollectionViewPadding = {
  10, 10, 10, 10
};
CGFloat const kPopTipPadding = 6;

@interface SEAShowtimesCell ()

@property (nonatomic) SEAShowtimesItemCell *highlightedCell;

@end

@implementation SEAShowtimesCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor clearColor];
  self.selectionStyle = UITableViewCellSelectionStyleGray;
  self.selectedBackgroundView = [UIView new];
  self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
  self.color = [UIColor colorWithHexString:kAmberColor];
  self.cells = [NSMutableArray new];

  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
  [self addGestureRecognizer:tapGestureRecognizer];
  UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
  [self addGestureRecognizer:longPressGestureRecognizer];

  return self;
}

#pragma mark UITableViewCell

- (void)prepareForReuse {
  self.collectionView.contentOffset = CGPointZero;
  self.cells = [NSMutableArray new];
  self.activeCell = nil;
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.selectedBackgroundView.frame = self.bounds;
}

#pragma mark Setters

- (void)setShowtimes:(NSMutableArray *)showtimes {
  _showtimes = showtimes;
  [self refresh];
}

- (void)setColor:(UIColor *)color {
  _color = color;
  [self.collectionView reloadData];
}

#pragma mark Public

- (BOOL)hasPoptip:(AMPopTip *)popTip {
  if (self.activeCell) {
    CGRect cellFrame = [self.collectionView convertRect:self.activeCell.frame toView:self.containerView];
    return CGRectEqualToRect(cellFrame, popTip.fromFrame);
  }
  return NO;
}

- (void)refresh {
}

#pragma mark Private

- (void)drawPopTipForCellAt:(NSIndexPath *)indexPath {
  SEAShowtimesItemCell *cell = (SEAShowtimesItemCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
  SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];
  CGRect cellFrame = [self.collectionView convertRect:cell.frame toView:self.containerView];
  AMPopTipDirection direction = AMPopTipDirectionDown;
  CGFloat distanceToEdge = self.containerView.contentSize.height - CGRectGetMaxY(cellFrame);

  if (distanceToEdge < 200 && self.containerView.contentSize.height >= self.containerView.height - 200) {
    direction = AMPopTipDirectionUp;
  }

  cell.label.textColor = [UIColor colorWithHexString:kOnyxColor];
  cell.layer.backgroundColor = cell.color.CGColor;
  self.popTip = [AMPopTip popTip];
  self.popTip.shouldDismissOnTap = NO;
  self.popTip.shouldDismissOnTapOutside = NO;
  self.popTip.edgeMargin = 5;
  self.popTip.offset = 2;
  self.popTip.popoverColor = [cell.color colorWithAlphaComponent:1];
  self.popTip.padding = 0;

  [self.popTip showCustomView:[self popTipViewForCellAt:indexPath] direction:direction inView:self.containerView fromFrame:cellFrame];
  __weak typeof(self) weakSelf = self;
  self.popTip.dismissHandler = ^{
    [cell resetView];
    weakSelf.popTipDelegate.visiblePopTip = nil;
  };
  self.popTip.tapHandler = ^{
    [weakSelf.popTipDelegate openShowtime:showtime];
  };
  self.activeCell = cell;
  self.popTipDelegate.visiblePopTip = self.popTip;
}

- (UIView *)popTipViewForCellAt:(NSIndexPath *)indexPath {
  SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];

  UIView *popTipView = [UIView new];
  UILabel *popTipLabel = [UILabel new];
  popTipLabel.attributedText = [showtime attributedDetailsString];
  popTipLabel.numberOfLines = 0;
  popTipLabel.size = [popTipLabel.attributedText boundingRectWithSize:CGSizeMake(200, (CGFloat)DBL_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
  popTipLabel.top = kPopTipPadding;
  popTipLabel.left = kPopTipPadding;
  [popTipView addSubview:popTipLabel];

  if ([showtime ticketonUrl]) {
    UIButton *popTipButton = [[UIButton alloc] initWithFrame:CGRectMake(0, popTipLabel.bottom + kPopTipPadding, popTipLabel.width + kPopTipPadding * 2, 44)];
    popTipButton.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    [popTipButton setTitleColor:[UIColor colorWithHexString:kOnyxColor] forState:UIControlStateNormal];
    [popTipButton setTitle:NSLocalizedString(@"Купить билет", nil) forState:UIControlStateNormal];
    [popTipButton setBackgroundImage:[UIImage imageWithColor:[[UIColor colorWithHexString:kOnyxColor] colorWithAlphaComponent:0.2f]] forState:UIControlStateNormal];
    [popTipButton setBackgroundImage:[UIImage imageWithColor:[[UIColor colorWithHexString:kOnyxColor] colorWithAlphaComponent:0.3f]] forState:UIControlStateHighlighted];
    __weak typeof(self) weakSelf = self;
    popTipButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
      [weakSelf.popTipDelegate buyTicketForShowtime:showtime];
      return [RACSignal empty];
    }];
    [popTipView addSubview:popTipButton];

    popTipView.frame = CGRectMake(0, 0, popTipButton.width, popTipButton.bottom);
  } else {
    popTipView.frame = CGRectMake(0, 0, popTipLabel.width + kPopTipPadding * 2, popTipLabel.bottom + kPopTipPadding);
  }

  return popTipView;
}

#pragma mark UICollectionViewDataSource

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return 5;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  return 5;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
  return kShowtimesCellCollectionViewPadding;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return (NSInteger)self.showtimes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self.popTipDelegate visiblePopTip]) {
    if (self.activeCell && [self.popTipDelegate cellForVisiblePopTip] == [self.collectionView cellForItemAtIndexPath:indexPath]) {
      [self.popTipDelegate.visiblePopTip hide];
      return;
    }
    __weak typeof(self) weakSelf = self;
    void (^oldDismissHandler)() = self.popTipDelegate.visiblePopTip.dismissHandler;
    self.popTipDelegate.visiblePopTip.dismissHandler = ^{
      oldDismissHandler();
      [weakSelf drawPopTipForCellAt:indexPath];
    };
    [self.popTipDelegate.visiblePopTip hide];
  } else {
    [self drawPopTipForCellAt:indexPath];
  }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [self.popTipDelegate hideVisiblePopTip];
}

#pragma mark Gesture recognizers

- (void)backgroundTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
  CGPoint tapLocation = [tapGestureRecognizer locationInView:self.collectionView];

  if ([self.popTipDelegate visiblePopTip] && ![self.collectionView indexPathForItemAtPoint:tapLocation]) {
    tapGestureRecognizer.cancelsTouchesInView = YES;
    [[self.popTipDelegate visiblePopTip] hide];
  } else {
    tapGestureRecognizer.cancelsTouchesInView = NO;
  }
}

- (void)pressed:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
  CGPoint pressLocation = [longPressGestureRecognizer locationInView:self.collectionView];
  NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:pressLocation];

  if (self.highlightedCell && (longPressGestureRecognizer.state == UIGestureRecognizerStateCancelled || longPressGestureRecognizer.state == UIGestureRecognizerStateFailed || longPressGestureRecognizer.state == UIGestureRecognizerStateEnded)) {
    [self.highlightedCell resetView];
    self.highlightedCell = nil;
  }

  if (indexPath) {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
      SEAShowtimesItemCell *cell = (SEAShowtimesItemCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
      cell.label.textColor = [UIColor colorWithHexString:kOnyxColor];
      cell.layer.backgroundColor = cell.color.CGColor;
      self.highlightedCell = cell;
    } else if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded) {
      SEAShowtime *showtime = self.showtimes[(NSUInteger)indexPath.row];
      [self.popTipDelegate openShowtime:showtime];
    }
  } else {
    longPressGestureRecognizer.cancelsTouchesInView = NO;
  }
}

@end
