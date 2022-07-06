#import "SEAMoviesPagerChildItemViewController.h"

#import "SEADataManager.h"
#import "SEAMoviesGridFeaturedMoviesView.h"
#import "SEAMoviesGridSectionHeader.h"
#import "SEAMovieViewController.h"
#import "UIView+AYUtils.h"
#import <Doppelganger/Doppelganger.h>
#import <MYNStickyFlowLayout.h>

CGFloat const kMoviesGridFeaturedMovieHeight = 150;

@interface SEAMoviesPagerChildItemViewController ()

@property (nonatomic) NSArray *movies;
@property (nonatomic) NSIndexPath *selectedCellIndexPath;
@property (nonatomic) NSArray *featuredMovies;
@property (nonatomic) SEAMoviesGridFeaturedMoviesView *featuredMoviesView;
@property (nonatomic) UITapGestureRecognizer *featuredMovieGesturedRecognizer;
@property (nonatomic) RACSignal *refreshSignal;

@end

@implementation SEAMoviesPagerChildItemViewController

#pragma mark Initialization

- (instancetype)initWithType:(SEAMoviesType)type {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.type = type;
  self.featuredMovieGesturedRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openFeaturedMovie)];
  [self setUpCollectionView];

  return self;
}

#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark Public

- (SEAMoviesGridCell *)selectedCell {
  if ([self isSelectedCellIndexPathVisible]) {
    return (SEAMoviesGridCell *)[self.collectionView cellForItemAtIndexPath:self.selectedCellIndexPath];
  }
  return nil;
}

- (CGRect)selectedCellFrame {
  if ([self isSelectedCellIndexPathVisible]) {
    NSInteger cols = (self.view.width <= 414) ? 3 : 4;
    NSInteger row = self.selectedCellIndexPath.row / cols;
    NSInteger col = self.selectedCellIndexPath.row >= cols ? self.selectedCellIndexPath.row % cols : self.selectedCellIndexPath.row;
    CGSize cellSize = [self posterSize];
    CGRect selectedCellFrame = CGRectMake(col * cellSize.width, row * cellSize.height, cellSize.width, cellSize.height);
    if (self.type == SEAMoviesTypeNowPlaying) {
      selectedCellFrame.origin.y += kMoviesGridFeaturedMovieHeight;
    } else {
      selectedCellFrame.origin.y += (self.selectedCellIndexPath.section + 1) * kDateSectionHeaderViewHeight;
      for (NSInteger section = 0; section < self.selectedCellIndexPath.section; section++) {
        NSInteger rowsInSection = (NSInteger)ceil((CGFloat)[self.collectionView numberOfItemsInSection:section] / (CGFloat)cols);
        selectedCellFrame.origin.y += rowsInSection * cellSize.height;
      }
    }
    return selectedCellFrame;
  }
  return CGRectZero;
}

- (RACSignal *)refresh {
  if (self.refreshSignal) {
    return self.refreshSignal;
  }
  self.refreshSignal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if (self.type == SEAMoviesTypeNowPlaying) {
      NSArray *oldMovies = self.movies;
      self.featuredMovies = [SEADataManager sharedInstance].featuredMovies;
      if (self.featuredMoviesView) {
        if (self.featuredMoviesView.shouldUsePercents != [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kShowPercentRatingsKey]) {
          self.featuredMoviesView = nil;
        }
      }
      self.movies = [[SEADataManager sharedInstance] filteredMovies:[[SEADataManager sharedInstance] localNowPlayingMovies]];
      if (self.isViewLoaded && self.view.window) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.movies previousArray:oldMovies];
        [self.collectionView wml_applyBatchChangesForRows:diffs inSection:0 completion:^(BOOL finished) {
          [self.collectionView reloadData];
          [subscriber sendCompleted];
        }];
      } else {
        [self.collectionView reloadData];
        [subscriber sendCompleted];
      }
    } else {
      self.movies = [SEADataManager sharedInstance].comingSoonMovies;
      [self.collectionView reloadData];
      [subscriber sendCompleted];
    }
    return nil;
  }] replayLazily] finally:^{
    self.refreshSignal = nil;
  }];
  return self.refreshSignal;
}

- (void)openMovie:(SEAMovie *)movie {
  if (self.type == SEAMoviesTypeNowPlaying) {
    self.selectedCellIndexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.movies indexOfObject:movie] inSection:0];
  } else {
    for (NSDate *date in [[SEADataManager sharedInstance] allDatesForComingSoonMovies]) {
      NSArray *movies = [SEADataManager filterMovies:self.movies date:date];
      if ([movies containsObject:movie]) {
        self.selectedCellIndexPath = [NSIndexPath indexPathForRow:(NSInteger)[movies indexOfObject:movie] inSection:0];
        break;
      }
    }
  }
  [self.delegate setHideTabBar:YES];
  SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:movie];
  [self.navigationController pushViewController:movieViewController animated:YES];
}

#pragma mark Private

- (void)setUpCollectionView {
  UICollectionViewFlowLayout *flowLayout;

  if (self.type == SEAMoviesTypeNowPlaying) {
    flowLayout = [UICollectionViewFlowLayout new];
  } else {
    flowLayout = [MYNStickyFlowLayout new];
  }
  flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

  self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
  self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;
  self.collectionView.backgroundColor = [UIColor clearColor];
  self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  [self.collectionView registerClass:[SEAMoviesGridCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAMoviesGridCell class])];
  if (self.type == SEAMoviesTypeNowPlaying) {
    [self.collectionView registerClass:[SEAMoviesGridFeaturedMoviesView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([SEAMoviesGridFeaturedMoviesView class])];
  } else {
    [self.collectionView registerClass:[SEAMoviesGridSectionHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([SEAMoviesGridSectionHeader class])];
  }
  [self.view addSubview:self.collectionView];
}

- (void)openFeaturedMovie {
  [self.featuredMoviesView invalidateTimer];
  SEAMovie *featuredMovie = self.featuredMoviesView.currentMovie;
  if ([self.movies indexOfObject:featuredMovie] != NSNotFound) {
    self.selectedCellIndexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.movies indexOfObject:featuredMovie] inSection:0];
  } else {
    self.selectedCellIndexPath = nil;
  }
  [self.delegate setHideTabBar:YES];
  SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:featuredMovie];
  [self.navigationController pushViewController:movieViewController animated:YES];
}

- (BOOL)isSelectedCellIndexPathVisible {
  if (!self.selectedCellIndexPath) {
    return NO;
  }
  BOOL visible = NO;
  for (SEAMoviesGridCell *cell in self.collectionView.visibleCells) {
    if ([self.collectionView indexPathForCell:cell] == self.selectedCellIndexPath) {
      visible = YES;
      break;
    }
  }
  return visible;
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (self.type == SEAMoviesTypeNowPlaying) {
    return (NSInteger)self.movies.count;
  } else {
    NSDate *date = [[SEADataManager sharedInstance] allDatesForComingSoonMovies][(NSUInteger)section];
    return (NSInteger)[SEADataManager filterMovies:self.movies date:date].count;
  }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  if (self.type == SEAMoviesTypeNowPlaying) {
    return 1;
  } else {
    return (NSInteger)[[SEADataManager sharedInstance] allDatesForComingSoonMovies].count;
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
  return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  return 0;
}

- (CGSize)posterSize {
  NSInteger cols = (self.view.width <= 414) ? 3 : 4;
  CGFloat posterWidth = self.view.width / cols;
  CGFloat posterHeight = posterWidth / 0.7f;

  return CGSizeMake(posterWidth, posterHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self posterSize];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
  if (self.type == SEAMoviesTypeNowPlaying) {
    return CGSizeMake(self.view.width, kMoviesGridFeaturedMovieHeight);
  } else {
    return CGSizeMake(self.view.width, kDateSectionHeaderViewHeight);
  }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  if (self.type == SEAMoviesTypeComingSoon) {
    SEAMoviesGridSectionHeader *headerView = (SEAMoviesGridSectionHeader *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([SEAMoviesGridSectionHeader class]) forIndexPath:indexPath];
    NSDate *date = [[SEADataManager sharedInstance] allDatesForComingSoonMovies][(NSUInteger)indexPath.section];
    NSLocale *ruLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMd" options:0 locale:ruLocale];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = ruLocale;
    dateFormatter.dateFormat = dateFormat;
    headerView.label.text = [dateFormatter stringFromDate:date];
    return headerView;
  } else {
    if (self.featuredMoviesView && self.featuredMoviesView.movies) {
      self.featuredMoviesView.width = self.view.width;
      return self.featuredMoviesView;
    } else {
      if (!self.featuredMoviesView) {
        self.featuredMoviesView = (SEAMoviesGridFeaturedMoviesView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([SEAMoviesGridFeaturedMoviesView class]) forIndexPath:indexPath];
      }
      if (self.featuredMovies && !self.featuredMoviesView.movies) {
        self.featuredMoviesView.movies = self.featuredMovies;
        [self.featuredMoviesView addGestureRecognizer:self.featuredMovieGesturedRecognizer];
      }
      return self.featuredMoviesView;
    }
  }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAMoviesGridCell *cell = (SEAMoviesGridCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAMoviesGridCell class]) forIndexPath:indexPath];

  if (self.type == SEAMoviesTypeNowPlaying) {
    cell.movie = self.movies[(NSUInteger)indexPath.row];
  } else {
    NSDate *date = [[SEADataManager sharedInstance] allDatesForComingSoonMovies][(NSUInteger)indexPath.section];
    cell.movie = [SEADataManager filterMovies:self.movies date:date][(NSUInteger)indexPath.row];
  }

  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  self.selectedCellIndexPath = indexPath;
  [self.delegate setHideTabBar:YES];
  SEAMovie *movie;
  if (self.type == SEAMoviesTypeNowPlaying) {
    movie = self.movies[(NSUInteger)indexPath.row];
  } else {
    NSDate *date = [[SEADataManager sharedInstance] allDatesForComingSoonMovies][(NSUInteger)indexPath.section];
    movie = [SEADataManager filterMovies:self.movies date:date][(NSUInteger)indexPath.row];
  }
  SEAMovieViewController *movieViewController = [[SEAMovieViewController alloc] initWithMovie:movie];
  [self.navigationController pushViewController:movieViewController animated:YES];
}

#pragma mark XLPagerTabStripViewControllerDelegate

- (NSString *)titleForPagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController {
  return (self.type == SEAMoviesTypeNowPlaying) ? NSLocalizedString(@"Сейчас в кино", nil) :
         NSLocalizedString(@"Скоро на экранах", nil);
}

@end
