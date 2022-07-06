#import "SEAPagerChildItemViewController.h"

#import "SEAMainTabBarController.h"
#import "UIView+AYUtils.h"

@interface SEAPagerChildItemViewController () <UIScrollViewDelegate, XLPagerTabStripChildItem>

@property (nonatomic) CGFloat dragStartPosition;
@property (nonatomic, getter = isDragging) BOOL dragging;

@end

@implementation SEAPagerChildItemViewController

#pragma mark Public

- (RACSignal *)refresh {
  return [RACSignal empty];
}

- (void)didRotate {
}

- (UIScrollView *)scrollView {
  return nil;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.dragStartPosition = (CGFloat)MAX(scrollView.contentOffset.y + scrollView.contentInset.top, 0);
  self.dragging = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  CGFloat position = targetContentOffset->y + scrollView.contentInset.top;

  if (self.isDragging) {
    self.dragging = NO;
    CGFloat diff = position - self.dragStartPosition;
    if (diff <= -self.delegate.topHeight / 2) {
      [self.delegate setPercentHidden:0 interactive:NO];
    } else if (diff > 0 && self.delegate.percentHidden > 0 && self.delegate.percentHidden < 1) {
      [self.delegate setPercentHidden:1 interactive:NO];
    }
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat position = scrollView.contentOffset.y + scrollView.contentInset.top;
  CGFloat diff = position - self.dragStartPosition;
  CGFloat toBottom = scrollView.contentSize.height - scrollView.height - position;

  if (position < 0) {
    [self.delegate setPercentHidden:0 interactive:NO];
  } else if (self.isDragging) {
    if (toBottom <= 0) {
      [self.delegate setPercentHidden:0 interactive:NO];
    } else if (self.delegate.percentHidden < 1 && diff > 0 && !self.delegate.isAnimatingBars) {
      CGFloat newPercent = MAX(0, MIN((diff / self.delegate.topHeight), 1));
      [self.delegate setPercentHidden:newPercent interactive:YES];
    }
  }
}

#pragma mark XLPagerTabStripViewControllerDelegate

- (NSString *)titleForPagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController {
  return nil;
}

@end
