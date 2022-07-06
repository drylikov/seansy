#import "XLButtonBarPagerTabStripViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@protocol SEAPagerChildItemViewControllerDelegate <NSObject>
@required
- (BOOL)isAnimatingBars;
- (CGFloat)bottomHeight;
- (CGFloat)percentHidden;
- (CGFloat)topHeight;
- (CGFloat)buttonBarHeight;
- (void)setHideTabBar:(BOOL)hideTabBar;
- (void)setPercentHidden:(CGFloat)percentHidden interactive:(BOOL)interactive;
- (void)updateBarsAnimated:(BOOL)animated;
@end

@interface SEAPagerChildItemViewController : UIViewController <UIScrollViewDelegate, XLPagerTabStripChildItem>

#pragma mark Properties

@property (weak, nonatomic) id<SEAPagerChildItemViewControllerDelegate> delegate;

#pragma mark Methods

- (UIScrollView *)scrollView;
- (RACSignal *)refresh;

@end
