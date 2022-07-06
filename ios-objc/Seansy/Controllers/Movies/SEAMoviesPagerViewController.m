#import "SEAMoviesPagerViewController.h"

#import "SEAAlertView.h"
#import "SEADataManager.h"
#import "SEAMoviesPagerChildItemViewController.h"
#import "UIView+AYUtils.h"

@interface SEAMoviesPagerViewController ()

@property (nonatomic) SEAMoviesPagerChildItemViewController *nowPlayingMoviesViewController;
@property (nonatomic) SEAMoviesPagerChildItemViewController *comingSoonMoviesViewController;

@end

@implementation SEAMoviesPagerViewController

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.nowPlayingMoviesViewController = [[SEAMoviesPagerChildItemViewController alloc] initWithType:SEAMoviesTypeNowPlaying];
  self.nowPlayingMoviesViewController.delegate = self;

  self.comingSoonMoviesViewController = [[SEAMoviesPagerChildItemViewController alloc] initWithType:SEAMoviesTypeComingSoon];
  self.comingSoonMoviesViewController.delegate = self;

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  __weak typeof(self) weakSelf = self;
  self.changeCurrentIndexProgressiveBlock = ^(XLButtonBarViewCell *oldCell, XLButtonBarViewCell *newCell, CGFloat progressPercentage, BOOL changeCurrentIndex, BOOL animated) {
    if (changeCurrentIndex) {
      [oldCell.label setTextColor:[UIColor colorWithWhite:1 alpha:0.6f]];
      [newCell.label setTextColor:[UIColor whiteColor]];
      NSIndexPath *newIndexPath = [weakSelf.buttonBarView indexPathForCell:newCell];
      for (UIBarButtonItem *barButtonItem in weakSelf.navigationItem.leftBarButtonItems) {
        barButtonItem.enabled = newIndexPath.row == 0;
      }
    }
  };
}

#pragma mark Public

- (RACSignal *)refresh {
  return [RACSignal merge:@[
            [self refreshNowPlayingMovies],
            [self refreshComingSoonMovies]
          ]];
}

- (RACSignal *)refreshNowPlayingMovies {
  return [self.nowPlayingMoviesViewController refresh];
}

- (RACSignal *)refreshComingSoonMovies {
  return [self.comingSoonMoviesViewController refresh];
}

- (id<SEAPosterViewDelegate>)lastSelectedPosterView {
  if (self.currentIndex == 0) {
    return self.nowPlayingMoviesViewController.selectedCell;
  } else {
    return self.comingSoonMoviesViewController.selectedCell;
  }
}

- (UIScrollView *)activeScrollView {
  if (self.currentIndex == 0) {
    return self.nowPlayingMoviesViewController.collectionView;
  } else {
    return self.comingSoonMoviesViewController.collectionView;
  }
}

- (void)openMovieWithId:(NSInteger)movieId {
  if (![SEADataManager sharedInstance].loaded) {
    return;
  }
  SEAMovie *movie = [[SEADataManager sharedInstance] movieForId:movieId];
  if (movie) {
    if (movie.date) {
      [self moveToViewController:self.comingSoonMoviesViewController];
      [self.comingSoonMoviesViewController performSelector:@selector(openMovie:) withObject:movie afterDelay:0.5f];
    } else {
      [self moveToViewController:self.nowPlayingMoviesViewController];
      [self.nowPlayingMoviesViewController performSelector:@selector(openMovie:) withObject:movie afterDelay:0.5f];
    }
  } else {
    SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:NSLocalizedString(@"Ошибка", nil) body:NSLocalizedString(@"Выбранный фильм не был найден. Возможно, он уже больше не идет в кино", nil)];
    [alertView show];
  }
}

#pragma mark RMPZoomTransitionAnimating

- (CGRect)transitionDestinationImageViewFrame {
  CGRect originalPosterFrame = CGRectZero;

  if (self.currentIndex == 0) {
    originalPosterFrame = self.nowPlayingMoviesViewController.selectedCellFrame;
  } else {
    originalPosterFrame = self.comingSoonMoviesViewController.selectedCellFrame;
  }

  if (CGRectEqualToRect(originalPosterFrame, CGRectZero)) {
    return originalPosterFrame;
  }

  originalPosterFrame = [self.activeScrollView convertRect:originalPosterFrame toView:self.navigationController.view];
  originalPosterFrame.origin.y += (-self.containerView.top + self.navigationController.navigationBar.bottom + self.buttonBarView.height);

  return originalPosterFrame;
}

#pragma mark XLPagerTabStripViewControllerDataSource

- (NSArray *)childViewControllersForPagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController {
  return @[self.nowPlayingMoviesViewController, self.comingSoonMoviesViewController];
}

@end
