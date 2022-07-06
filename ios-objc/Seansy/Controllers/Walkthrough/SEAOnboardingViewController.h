#import "SEAOnboardingContentViewController.h"

@interface SEAOnboardingViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate>

#pragma mark Properties

/**
 *  Contains the view controllers for the pages.
 */
@property (nonatomic) NSArray *viewControllers;
/**
 *  Currently visible content view controller.
 */
@property (nonatomic) SEAOnboardingContentViewController *currentPage;
/**
 *  Next content view controller in the queue.
 */
@property (nonatomic) SEAOnboardingContentViewController *upcomingPage;
/**
 *  The color for the background behind the view controllers.
 */
@property (nonatomic) UIColor *backgroundColor;
/**
 *  Whether or not there should be fading of the view controllers on swipe.
 */
@property (nonatomic) BOOL shouldFadeTransitions;
/**
 *  Whether or not the last page should fade away on exit.
 */
@property (nonatomic) BOOL fadePageControlOnLastPage;
/**
 *  Whether or not there should be a button that will allow skipping.
 */
@property (nonatomic) BOOL allowSkipping;
/**
 *  The action that will execute when the skip button is pressed.
 */
@property (strong, nonatomic) dispatch_block_t skipHandler;
/**
 *  Whether or not moving between pages by swiping should be allowed.
 */
@property (nonatomic) BOOL swipingEnabled;
/**
 *  Whether or not the bullets for page control should be hidden.
 */
@property (nonatomic) BOOL hidePageControl;
/**
 *  The page control of the tutorial view controller.
 */
@property (nonatomic) UIPageControl *pageControl;
/**
 *  Color for the page control background.
 */
@property (nonatomic) UIColor *pageControlColor;
/**
 *  The tint color to be used for the page indicator on page control.
 */
@property (nonatomic) UIColor *pageIndicatorTintColor;
/**
 *  The tint color to be used for the current page indicator on page control.
 */
@property (nonatomic) UIColor *currentPageIndicatorTintColor;
/**
 *  The button which allows exiting the view.
 */
@property (nonatomic) UIButton *skipButton;
/**
 *  The text on the skip button.
 */
@property (nonatomic) NSString *skipButtonText;
/**
 *  Color for the skip button label.
 */
@property (nonatomic) UIColor *skipButtonColor;
/**
 *  Optional title label shown at the top of the view.
 */
@property (nonatomic) UILabel *titleLabel;
/**
 *  Text for the optional title label.
 */
@property (copy, nonatomic) NSString *titleText;
/**
 *  Color for the title label.
 */
@property (nonatomic) UIColor *titleLabelColor;

#pragma mark Methods

/**
 *  Creates an onboarding view controller with the given contents.
 *
 *  @param contents Array with the view controllers for the pages.
 *
 *  @return Newly created onboarding view controller.
 */
- (instancetype)initWithContents:(NSArray *)contents;
/**
 *  Manually scrolls to the next page.
 */
- (void)moveNextPage;
/**
 *  Perform the completion handler.
 */
- (void)performCompletionHandler;

@end
