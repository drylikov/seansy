//
//  XLButtonBarPagerTabStripViewController.m
//  XLPagerTabStrip ( https://github.com/xmartlabs/XLPagerTabStrip )
//
//  Copyright (c) 2015 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "XLButtonBarPagerTabStripViewController.h"

#import "SEAConstants.h"
#import "XLButtonBarViewCell.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"

@interface XLButtonBarPagerTabStripViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) XLButtonBarView *buttonBarView;
@property (nonatomic) BOOL shouldUpdateButtonBarView;

@end

@implementation XLButtonBarPagerTabStripViewController {
    XLButtonBarViewCell * _sizeCell;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.shouldUpdateButtonBarView = YES;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.buttonBarView.leftRightMargin = 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UICollectionViewLayoutAttributes *attributes = [self.buttonBarView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)self.currentIndex inSection:0]];
    CGRect cellRect = attributes.frame;
    self.buttonBarView.selectedBar.frame = CGRectMake(CGRectGetMinX(cellRect), self.buttonBarView.height - self.buttonBarView.selectedBarHeight - 2, CGRectGetWidth(cellRect), self.buttonBarView.selectedBarHeight);
}

- (void)reloadPagerTabStripView {
    [super reloadPagerTabStripView];
    if ([self isViewLoaded]) {
        [self.buttonBarView reloadData];
        [self.buttonBarView moveToIndex:self.currentIndex animated:NO swipeDirection:XLPagerTabStripDirectionNone];
    }
}

#pragma mark - Properties

- (XLButtonBarView *)buttonBarView {
    if (_buttonBarView) return _buttonBarView;
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    CGFloat width;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        width = CGRectGetWidth([UIScreen mainScreen].bounds);
    } else {
        width = CGRectGetHeight([UIScreen mainScreen].bounds);
    }
    _buttonBarView = [[XLButtonBarView alloc] initWithFrame:CGRectMake(0, 0, width, 44) collectionViewLayout:flowLayout];
    _buttonBarView.centerX = self.view.centerX;
    _buttonBarView.delegate = self;
    _buttonBarView.dataSource = self;
    _buttonBarView.selectedBar.backgroundColor = [UIColor colorWithHexString:kAmberColor];
    _buttonBarView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _buttonBarView.showsHorizontalScrollIndicator = NO;
    _buttonBarView.scrollsToTop = NO;
    [_buttonBarView registerClass:[XLButtonBarViewCell class] forCellWithReuseIdentifier:NSStringFromClass([XLButtonBarViewCell class])];
    return _buttonBarView;
}

#pragma mark - XLPagerTabStripViewControllerDelegate

- (void)pagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex {
    if (self.shouldUpdateButtonBarView) {
        XLPagerTabStripDirection direction = XLPagerTabStripDirectionLeft;
        if (toIndex < fromIndex) {
            direction = XLPagerTabStripDirectionRight;
        }
        [self.buttonBarView moveToIndex:(NSUInteger)toIndex animated:YES swipeDirection:direction];
        if (self.changeCurrentIndexBlock) {
            XLButtonBarViewCell *oldCell = (XLButtonBarViewCell *)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex != (NSUInteger)fromIndex ? fromIndex : toIndex inSection:0]];
            XLButtonBarViewCell *newCell = (XLButtonBarViewCell *)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)self.currentIndex inSection:0]];
            self.changeCurrentIndexBlock(oldCell, newCell, YES);
        }
    }
}

- (void)pagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex
            withProgressPercentage:(CGFloat)progressPercentage
                   indexWasChanged:(BOOL)indexWasChanged {
    if (self.shouldUpdateButtonBarView) {
        [self.buttonBarView moveFromIndex:fromIndex toIndex:toIndex withProgressPercentage:progressPercentage];
        if (self.changeCurrentIndexProgressiveBlock) {
            XLButtonBarViewCell *oldCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex != (NSUInteger)fromIndex ? fromIndex : toIndex inSection:0]];
            XLButtonBarViewCell *newCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)self.currentIndex inSection:0]];
            self.changeCurrentIndexProgressiveBlock(oldCell, newCell, progressPercentage, indexWasChanged, YES);
        }
    }
}

#pragma merk - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width;
    if (self.pagerTabStripChildViewControllers.count == 2) {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            width = CGRectGetWidth([UIScreen mainScreen].bounds)/2;
        } else {
            width = CGRectGetHeight([UIScreen mainScreen].bounds)/2;
        }
    } else {
        UILabel *label = [UILabel new];
        label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
        UIViewController<XLPagerTabStripChildItem> *childController = self.pagerTabStripChildViewControllers[(NSUInteger)indexPath.item];
        label.text = [childController titleForPagerTabStripViewController:self];
        [label sizeToFit];
        width = label.width + (self.buttonBarView.leftRightMargin * 2);
    }
    
    return CGSizeMake(width, collectionView.height);
}

#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //There's nothing to do if we select the current selected tab
    if ((NSUInteger)indexPath.item == self.currentIndex) {
		return;
    }
	
    [self.buttonBarView moveToIndex:(NSUInteger)indexPath.item animated:YES swipeDirection:XLPagerTabStripDirectionNone];
    self.shouldUpdateButtonBarView = NO;
    
    XLButtonBarViewCell *oldCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)self.currentIndex inSection:0]];
    XLButtonBarViewCell *newCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    if (self.isProgressiveIndicator) {
        if (self.changeCurrentIndexProgressiveBlock) {
            self.changeCurrentIndexProgressiveBlock(oldCell, newCell, 1, YES, YES);
        }
    } else{
        if (self.changeCurrentIndexBlock) {
            self.changeCurrentIndexBlock(oldCell, newCell, YES);
        }
    }
    
    [self moveToViewControllerAtIndex:(NSUInteger)indexPath.item];
}

#pragma merk - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)self.pagerTabStripChildViewControllers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XLButtonBarViewCell *cell = (XLButtonBarViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([XLButtonBarViewCell class]) forIndexPath:indexPath];
    UIViewController<XLPagerTabStripChildItem> *childController =   [self.pagerTabStripChildViewControllers objectAtIndex:(NSUInteger)indexPath.item];
    
    cell.label.text = [childController titleForPagerTabStripViewController:self];
    
    if (self.isProgressiveIndicator) {
        if (self.changeCurrentIndexProgressiveBlock) {
            self.changeCurrentIndexProgressiveBlock(self.currentIndex == (NSUInteger)indexPath.item ? nil : cell , self.currentIndex == (NSUInteger)indexPath.item ? cell : nil, 1, YES, NO);
        }
    } else {
        if (self.changeCurrentIndexBlock) {
            self.changeCurrentIndexBlock(self.currentIndex == (NSUInteger)indexPath.item ? nil : cell , self.currentIndex == (NSUInteger)indexPath.item ? cell : nil, NO);
        }
    }
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [super scrollViewDidEndScrollingAnimation:scrollView];
    if (scrollView == self.containerView){
        self.shouldUpdateButtonBarView = YES;
    }
}

@end
