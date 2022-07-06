@class SEAOnboardingViewController;

@interface SEAOnboardingContentViewController : UIViewController

#pragma mark Properties

/**
 * The parent delegate controlling the view.
 */
@property (nonatomic) SEAOnboardingViewController *delegate;
/**
 *  Color of the background view.
 */
@property (nonatomic) UIColor *backgroundColor;
/**
 *  Color of the title label text.
 */
@property (nonatomic) UIColor *titleColor;
/**
 *  Color of the subtitle label text.
 */
@property (nonatomic) UIColor *subtitleColor;
/**
 *  Size of the title label font.
 */
@property (nonatomic) CGFloat titleFontSize;
/**
 *  Size of the subtitle label font.
 */
@property (nonatomic) CGFloat subtitleFontSize;
/**
 *  Color of the continue button.
 */
@property (nonatomic) UIColor *continueButtonColor;
/**
 *  Action that will execute before the view appears.
 */
@property (copy, nonatomic) dispatch_block_t viewWillAppearBlock;
/**
 *  Action that will execute as soon as the view appears.
 */
@property (copy, nonatomic) dispatch_block_t viewDidAppearBlock;
/**
 *  Indicates if the view controller is for showing a new feature.
 */
@property (nonatomic, getter = isNewFeature) BOOL newFeature;

#pragma mark Methods

- (instancetype)initWithTitleText:(NSString *)titleText subtitleText:(NSString *)subtitleText image:(UIImage *)image showButton:(BOOL)showButton;
- (void)updateAlpha:(CGFloat)newAlpha;

@end
