#import "SEAActionSheet.h"
#import "SEAPagerChildItemViewController.h"
#import "SEATabBarItemViewControllerDelegate.h"
#import "SEAZoomTransitionAnimator.h"
#import "XLButtonBarPagerTabStripViewController.h"

@protocol SEAPosterViewDelegate <NSObject>
@required
- (UIImageView *)poster;
- (void)restorePoster;
@end

@interface SEAPagerViewController : XLButtonBarPagerTabStripViewController <SEAPagerChildItemViewControllerDelegate, SEAZoomTransitionAnimating, SEAZoomTransitionDelegate, SEATabBarItemViewControllerDelegate>

#pragma mark Properties

@property (nonatomic, getter = isReady) BOOL ready;

#pragma mark Methods

- (id<SEAPosterViewDelegate>)lastSelectedPosterView;
- (UICollectionView *)activeScrollView;
- (void)restoreLastSelectedPoster;
- (void)showActionSheet:(SEAActionSheet *)actionSheet;

@end
