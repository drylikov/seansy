#import "SEAMoviesGridFeaturedMoviesView.h"

#import "SEAConstants.h"
#import "SEAFeaturedMovieView.h"
#import "UIView+AYUtils.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SEAMoviesGridFeaturedMoviesView () <UIScrollViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) NSTimer *autoScrollingTimer;

@end

@implementation SEAMoviesGridFeaturedMoviesView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.scrollView.pagingEnabled = YES;
  self.scrollView.delegate = self;
  self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

  [self addSubview:self.scrollView];
  [self addSubview:self.activityIndicator];
  [self.activityIndicator startAnimating];
  self.scrollView.layer.transform = CATransform3DMakeRotation((CGFloat)M_PI_2, 1, 0, 0);

  return self;
}

#pragma mark UICollectionReusableView

- (void)prepareForReuse {
  [self.activityIndicator startAnimating];
  self.movies = nil;
  [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.activityIndicator.center = self.center;
}

#pragma mark Setters

- (void)setMovies:(NSArray *)movies {
  _movies = movies.count > 1 ? [movies arrayByAddingObject:movies[0]] : movies;
  self.usePercents = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kShowPercentRatingsKey];
  [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  NSMutableArray *signals = [NSMutableArray new];
  [self.movies enumerateObjectsUsingBlock:^(SEAMovie *movie, NSUInteger idx, BOOL *stop) {
    SEAFeaturedMovieView *featuredMovieView = [[SEAFeaturedMovieView alloc] initWithFrame:CGRectOffset(self.scrollView.bounds, self.scrollView.width * idx, 0)];
    featuredMovieView.usePercents = self.usePercents;
    [self.scrollView addSubview:featuredMovieView];
    [signals addObject:[featuredMovieView updateMovie:movie]];
  }];
  self.scrollView.contentSize = CGSizeMake(self.scrollView.width * self.movies.count, self.scrollView.height);
  if (signals.count > 0) {
    [signals[0] subscribeCompleted:^{
#ifndef SNAPSHOT
      if (!self.autoScrollingTimer) {
        self.autoScrollingTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(loadNextPage) userInfo:nil repeats:YES];
      }
#endif
      [self.activityIndicator stopAnimating];
      [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0 options:0 animations:^{
        self.scrollView.layer.transform = CATransform3DIdentity;
      } completion:nil];
    }];
    [[RACSignal merge:[signals subarrayWithRange:NSMakeRange(1, signals.count - 1)]] subscribeCompleted:^{
      DDLogVerbose(@"Finished updating featured movies");
    }];
  }
}

#pragma mark Public

- (SEAMovie *)currentMovie {
  return self.movies.count > 0 ? self.movies[self.currentPage] : nil;
}

- (void)invalidateTimer {
  if (self.autoScrollingTimer.isValid) {
    [self.autoScrollingTimer invalidate];
  }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (self.movies.count > 1 && scrollView.contentOffset.x == scrollView.width * (self.movies.count - 1)) {
    [self loadPageIndex:0 animated:NO];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self invalidateTimer];
}

#pragma mark Private

- (NSUInteger)currentPage {
  CGFloat pageWidth = self.scrollView.width;
  CGFloat fractionalPage = self.scrollView.contentOffset.x / pageWidth;
  return (NSUInteger)lround(fractionalPage);
}

- (void)loadNextPage {
  [self loadNextPage:YES];
}

- (void)loadPreviousPage {
  [self loadPreviousPage:YES];
}

- (void)loadNextPage:(BOOL)animated {
  [self loadPageIndex:self.currentPage + 1 animated:animated];
}

- (void)loadPreviousPage:(BOOL)animated {
  [self loadPageIndex:self.currentPage - 1 animated:animated];
}

- (void)loadPageIndex:(NSUInteger)index animated:(BOOL)animated {
  [self.scrollView setContentOffset:CGPointMake(self.scrollView.width * index, 0) animated:animated];
}

@end
