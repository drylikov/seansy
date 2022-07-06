//
//  Copyright (c) 2014 Akio Yasui, 2015 Ayan Yenbekbay.
//

#import "SEAPickerView.h"

#import "SEAConstants.h"
#import "SEADataManager.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"
#import <Availability.h>

@interface SEAPickerViewCell : UICollectionViewCell

@property (nonatomic) UILabel *label;
@property (nonatomic) UIView *centerLine;
@property (nonatomic) UIView *rightLine;

@end

@interface SEAPickerView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) NSUInteger selectedItem;
@property (nonatomic) NSUInteger targetItem;

@end

@implementation SEAPickerView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.font = [UIFont lightFontWithSize:[UIFont largeTextFontSize]];
  self.selectedFont = [UIFont lightFontWithSize:[UIFont largeTextFontSize] + 4];
  self.textColor = [UIColor colorWithWhite:1 alpha:kDisabledAlpha];
  self.selectedTextColor = [UIColor whiteColor];
  self.selectedItem = NSNotFound;
  self.targetItem = NSNotFound;
  self.selectOnScroll = YES;
  self.didMoveManually = NO;

  UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
  flowLayout.sectionInset = UIEdgeInsetsZero;
  flowLayout.minimumInteritemSpacing = 0;
  flowLayout.minimumLineSpacing = 0;
  flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
  self.collectionView.showsHorizontalScrollIndicator = NO;
  self.collectionView.backgroundColor = [UIColor clearColor];
  self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.scrollsToTop = NO;
  [self.collectionView registerClass:[SEAPickerViewCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAPickerViewCell class])];
  [self addSubview:self.collectionView];

  self.maskDisabled = NO;

  return self;
}

#pragma mark Lifecycle

- (void)layoutSubviews {
  [super layoutSubviews];
  if ([self.dataSource numberOfItemsInPickerView:self] > 0 && self.selectedItem < [self.dataSource numberOfItemsInPickerView:self] && self.selectedItem != NSNotFound) {
    [self scrollToItem:self.selectedItem animated:NO];
  }
  self.collectionView.layer.mask.frame = self.collectionView.bounds;
}

- (void)dealloc {
  self.collectionView.delegate = nil;
}

#pragma mark Setters

- (void)setMaskDisabled:(BOOL)maskDisabled {
  _maskDisabled = maskDisabled;

  self.collectionView.layer.mask = maskDisabled ? nil : ({
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    maskLayer.frame = self.collectionView.bounds;
    maskLayer.colors = @[(id)[[UIColor clearColor] CGColor],
                         (id)[[UIColor blackColor] CGColor],
                         (id)[[UIColor blackColor] CGColor],
                         (id)[[UIColor clearColor] CGColor], ];
    maskLayer.locations = @[@0, @0.33f, @0.66f, @1];
    maskLayer.startPoint = CGPointMake(0, 0);
    maskLayer.endPoint = CGPointMake(1, 0);
    maskLayer;
  });
}

#pragma mark Private

- (void)reloadData {
  [self.collectionView.collectionViewLayout invalidateLayout];
  [self.collectionView reloadData];
}

- (void)selectItem:(NSUInteger)item animated:(BOOL)animated {
  [self selectItem:item animated:animated notifySelection:YES];
}

- (void)selectItem:(NSUInteger)item animated:(BOOL)animated notifySelection:(BOOL)notifySelection {
  [self scrollToItem:item animated:animated];
  if (notifySelection && [self.delegate respondsToSelector:@selector(pickerView:didSelectItem:)]) {
    [self.delegate pickerView:self didSelectItem:(NSInteger)item];
  }
}

- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated {
  if (self.collectionView.contentSize.width == 0) {
    [self.collectionView layoutIfNeeded];
  }
  if (self.contentOffset.x == 0 && item == 0) {
    [self updateSelectedItem:item];
  } else {
    self.targetItem = item;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)item inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
  }
}

- (void)didEndScrolling {
  CGPoint center = [self convertPoint:self.collectionView.center toView:self.collectionView];
  NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:center];
  [self selectItem:(NSUInteger)indexPath.item animated:YES];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return [self.dataSource numberOfItemsInPickerView:self] > 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return (NSInteger)[self.dataSource numberOfItemsInPickerView:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAPickerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAPickerViewCell class]) forIndexPath:indexPath];

  NSDate *date = [self.dataSource pickerView:self dateForItem:indexPath.item];
  NSString *title = [self titleFromDate:date];

  cell.label.text = title;
  cell.label.textColor = ((NSUInteger)indexPath.item == self.selectedItem) ? self.selectedTextColor : self.textColor;
  cell.label.font = ((NSUInteger)indexPath.item == self.selectedItem) ? self.selectedFont : self.font;
  cell.label.bounds = (CGRect) {
    CGPointZero, [self sizeForString:title]
  };
  if ([SEADataManager hasPassed:date]) {
    cell.alpha = 0.75f;
  }

  for (UIView *line in @[cell.centerLine, cell.rightLine]) {
    line.backgroundColor = self.textColor;
  }

  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  CGSize size = CGSizeMake(self.interitemSpacing, self.collectionView.height);
  NSString *title = [self titleFromDate:[self.dataSource pickerView:self dateForItem:indexPath.item]];

  size.width += [self sizeForString:title].width;
  return size;
}

- (NSString *)titleFromDate:(NSDate *)date {
  NSDateFormatter *dateFormatter = [NSDateFormatter new];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Almaty"];
  dateFormatter.dateFormat = @"HH:mm";
  return [dateFormatter stringFromDate:date];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
  NSInteger number = [self collectionView:collectionView numberOfItemsInSection:section];
  NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
  CGSize firstSize = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:firstIndexPath];
  NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:number - 1 inSection:section];
  CGSize lastSize = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:lastIndexPath];

  return UIEdgeInsetsMake(0, (collectionView.width - firstSize.width) / 2, 0, (collectionView.width - lastSize.width) / 2);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  self.didMoveManually = YES;
  [self selectItem:(NSUInteger)indexPath.item animated:YES];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.didMoveManually = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (!scrollView.isTracking) {
    [self didEndScrolling];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    [self didEndScrolling];
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [CATransaction begin];
  [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
  self.collectionView.layer.mask.frame = self.collectionView.bounds;
  [CATransaction commit];

  CGPoint center = [self convertPoint:self.collectionView.center toView:self.collectionView];
  if (self.shouldSelectOnScroll && center.x >= 0 && center.x < self.collectionView.contentSize.width - self.collectionView.width / 2) {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:center];
    if (self.targetItem == (NSUInteger)indexPath.item) {
      self.targetItem = NSNotFound;
      [self updateSelectedItem:(NSUInteger)indexPath.item];
    } else if (self.selectedItem != (NSUInteger)indexPath.item && self.targetItem == NSNotFound) {
      [self updateSelectedItem:(NSUInteger)indexPath.item];
    }
  }
}

- (void)updateSelectedItem:(NSUInteger)selectedItem {
  SEAPickerViewCell *previousSelectedCell = (SEAPickerViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)self.selectedItem inSection:0]];
  SEAPickerViewCell *currentSelectedCell = (SEAPickerViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)selectedItem inSection:0]];

  previousSelectedCell.label.textColor = self.textColor;
  previousSelectedCell.label.font = self.font;
  [previousSelectedCell setNeedsLayout];
  currentSelectedCell.label.textColor = self.selectedTextColor;
  currentSelectedCell.label.font = self.selectedFont;
  [currentSelectedCell setNeedsLayout];

  self.selectedItem = selectedItem;
}

#pragma mark Helpers

- (CGSize)sizeForString:(NSString *)string {
  CGSize size;
  CGSize selectedSize;

  size = [string sizeWithAttributes:@{ NSFontAttributeName : self.font }];
  selectedSize = [string sizeWithAttributes:@{ NSFontAttributeName : self.selectedFont }];
  return CGSizeMake(ceilf((float)MAX(size.width, selectedSize.width)), ceilf((float)MAX(size.height, selectedSize.height)));
}

@end

@implementation SEAPickerViewCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.layer.doubleSided = NO;
  self.label = [[UILabel alloc] initWithFrame:self.contentView.bounds];
  self.label.backgroundColor = [UIColor clearColor];
  self.label.numberOfLines = 1;
  self.label.lineBreakMode = NSLineBreakByTruncatingTail;
  self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.contentView addSubview:self.label];

  CGFloat centerLineHeight = self.contentView.height / 2 - 10;
  self.centerLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentView.height - centerLineHeight, 1 / [UIScreen mainScreen].scale, centerLineHeight)];
  [self.contentView addSubview:self.centerLine];

  CGFloat rightLineHeight = centerLineHeight / 2;
  self.rightLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentView.height - rightLineHeight, 1 / [UIScreen mainScreen].scale, rightLineHeight)];
  [self.contentView addSubview:self.rightLine];

  return self;
}

- (void)layoutSubviews {
  [self.label sizeToFit];
  self.label.centerX = self.contentView.centerX - 1 / [UIScreen mainScreen].scale;
  self.label.bottom = self.contentView.centerY;
  self.centerLine.centerX = self.label.centerX;
  self.rightLine.right = self.contentView.right;
}

@end
