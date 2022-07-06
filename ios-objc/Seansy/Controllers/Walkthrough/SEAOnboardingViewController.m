#import "SEAOnboardingViewController.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"

static CGFloat const kOnboardingSkipButtonWidth = 100;

@interface SEAOnboardingViewController ()

@property (nonatomic) UIPageViewController *pageVC;

@end

@implementation SEAOnboardingViewController

#pragma mark Initialization

- (instancetype)initWithContents:(NSArray *)contents {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.edgesForExtendedLayout = UIRectEdgeNone;
  // Store the passed in view controllers array
  self.viewControllers = contents;
  // Set the default properties
  self.shouldFadeTransitions = NO;
  self.fadePageControlOnLastPage = NO;
  self.swipingEnabled = YES;
  self.hidePageControl = NO;
  self.allowSkipping = NO;
  self.skipHandler = ^{};
  // Create the initial exposed components so they can be customized
  self.pageControl = [UIPageControl new];
  self.skipButton = [UIButton new];
  self.titleLabel = [UILabel new];

  return self;
}

#pragma mark View

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)setUpView {
  // Create our page view controller
  self.view.backgroundColor = self.backgroundColor ? : [UIColor clearColor];
  self.pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
  self.pageVC.view.frame = self.view.frame;
  self.pageVC.delegate = self;
  self.pageVC.dataSource = self.swipingEnabled ? self : nil;

  // Set the initial current page as the first page provided
  self.currentPage = [self.viewControllers firstObject];

  // More page controller setup
  [self.pageVC setViewControllers:@[self.currentPage] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
  [self addChildViewController:self.pageVC];
  [self.view addSubview:self.pageVC.view];
  [self.pageVC didMoveToParentViewController:self];

  // Create and configure the the page control
  if (!self.hidePageControl) {
    self.pageControl.frame = CGRectMake(0, self.view.bottom - kOnboardingBottomHeight, self.view.width, kOnboardingBottomHeight);
    self.pageControl.backgroundColor = self.pageControlColor ? : [UIColor colorWithWhite:0 alpha:0.25f];
    self.pageControl.pageIndicatorTintColor = self.pageIndicatorTintColor ? : [UIColor colorWithWhite:1 alpha:0.5f];
    self.pageControl.currentPageIndicatorTintColor = self.currentPageIndicatorTintColor ? : [UIColor whiteColor];
    self.pageControl.numberOfPages = (NSInteger)self.viewControllers.count;
    self.pageControl.userInteractionEnabled = NO;
    [self.view addSubview:self.pageControl];
  }

  // If we allow skipping, setup the skip button
  if (self.allowSkipping) {
    self.skipButton.frame = CGRectMake(self.view.right - kOnboardingSkipButtonWidth, self.view.bottom - kOnboardingBottomHeight, kOnboardingSkipButtonWidth, kOnboardingBottomHeight);
    [self.skipButton setTitle:self.skipButtonText forState:UIControlStateNormal];
    self.skipButton.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    [self.skipButton setTitleColor:self.skipButtonColor ? : [UIColor whiteColor] forState:UIControlStateNormal];
    [self.skipButton addTarget:self action:@selector(performCompletionHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipButton];
  }

  // If there is a title, show it
  if (self.titleText) {
    self.titleLabel.font = [UIFont regularFontWithSize:[UIFont largeTextFontSize]];
    self.titleLabel.textColor = self.titleLabelColor ? : [UIColor whiteColor];
    self.titleLabel.text = self.titleText;
    [self.titleLabel sizeToFit];
    self.titleLabel.height = kOnboardingTopHeight;
    self.titleLabel.top = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    self.titleLabel.centerX = self.view.centerX;
    [self.view addSubview:self.titleLabel];
  }

  // If we want to fade the transitions, we need to tap into the underlying scrollview
  // so we can set ourself as the delegate, this is sort of hackish but the only current
  // solution I am aware of using a page view controller
  if (self.shouldFadeTransitions) {
    for (UIView *view in self.pageVC.view.subviews) {
      if ([view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)view setDelegate:self];
      }
    }
  }

  // Set ourself as the delegate on all of the content views, to handle fading
  // and auto-navigation
  for (SEAOnboardingContentViewController *contentVC in self.viewControllers) {
    contentVC.delegate = self;
  }
}

#pragma mark Setters

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  _backgroundColor = backgroundColor;
  self.view.backgroundColor = backgroundColor;
}

- (void)setPageControlColor:(UIColor *)pageControlColor {
  _pageControlColor = pageControlColor;
  self.pageControl.backgroundColor = pageControlColor;
}

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
  _pageIndicatorTintColor = pageIndicatorTintColor;
  self.pageControl.pageIndicatorTintColor = pageIndicatorTintColor;
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
  _currentPageIndicatorTintColor = currentPageIndicatorTintColor;
  self.pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor;
}

- (void)setSkipButtonColor:(UIColor *)skipButtonColor {
  _skipButtonColor = skipButtonColor;
  [self.skipButton setTitleColor:skipButtonColor forState:UIControlStateNormal];
}

- (void)setTitleLabelColor:(UIColor *)titleLabelColor {
  _titleLabelColor = titleLabelColor;
  self.titleLabel.textColor = titleLabelColor;
}

#pragma mark Skipping

- (void)performCompletionHandler {
  self.skipHandler();
}

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
  // Return the previous view controller in the array unless we're at the beginning
  if (viewController == [self.viewControllers firstObject]) {
    return nil;
  } else {
    NSUInteger priorPageIndex = [self.viewControllers indexOfObject:viewController] - 1;
    return self.viewControllers[priorPageIndex];
  }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
  // Return the next view controller in the array unless we're at the end
  if (viewController == [self.viewControllers lastObject]) {
    return nil;
  } else {
    NSUInteger nextPageIndex = [self.viewControllers indexOfObject:viewController] + 1;
    return self.viewControllers[nextPageIndex];
  }
}

#pragma mark UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
  // If we haven't completed animating yet, we don't want to do anything because it could be cancelled
  if (!completed) {
    return;
  }

  // Get the view controller we are moving towards, then get the index, then set it as the current page
  // for the page control dots
  UIViewController *viewController = [pageViewController.viewControllers lastObject];
  NSUInteger newIndex = [self.viewControllers indexOfObject:viewController];
  self.pageControl.currentPage = (NSInteger)newIndex;
}

- (void)moveNextPage {
  NSUInteger indexOfNextPage = [self.viewControllers indexOfObject:self.currentPage] + 1;

  if (indexOfNextPage < self.viewControllers.count) {
    [self.pageVC setViewControllers:@[self.viewControllers[indexOfNextPage]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    self.pageControl.currentPage = (NSInteger)indexOfNextPage;
  }
}

#pragma mark Page Scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // Calculate the percent complete of the transition of the current page given the
  // scrollview's offset and the width of the screen
  CGFloat percentComplete = (CGFloat)(fabs(scrollView.contentOffset.x - self.view.width) / self.view.width);

  // These cases have some funk results given the way this method is called, like stuff
  // just disappearing, so we want to do nothing in these cases
  if (self.upcomingPage == self.currentPage || percentComplete == 0) {
    return;
  }

  // Set the next page's alpha to be the percent complete, so if we're 90% of the way
  // scrolling towards the next page, its content's alpha should be 90%
  [self.upcomingPage updateAlpha:percentComplete];
  // Set the current page's alpha to the difference between 100% and this percent value,
  // so we're 90% scrolling towards the next page, the current content's alpha sshould be 10%
  [self.currentPage updateAlpha:1 - percentComplete];

  // If we want to fade the page control on the last page...
  if (self.fadePageControlOnLastPage) {
    // If the upcoming page is the last object, fade the page control out as we scroll.
    if (self.upcomingPage == [self.viewControllers lastObject]) {
      self.pageControl.alpha = 1 - percentComplete;
    }
    // Otherwise if we're on the last page and we're moving towards the second-to-last page, fade it back in.
    else if (self.currentPage == [self.viewControllers lastObject] && self.upcomingPage == self.viewControllers[self.viewControllers.count - 2]) {
      self.pageControl.alpha = percentComplete;
    }
  }
}

@end
