#import "SEAOnboardingContentViewController.h"

#import "SEAConstants.h"
#import "SEAOnboardingViewController.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"

CGFloat const kOnboardingWindowPadding = 20;
CGFloat const kOnboardingTitleLabelTopMargin = 30;
CGFloat const kOnboardingLabelSpacing = 10;
CGFloat const kOnboardingContinueButtonTopMargin = 20;
UIEdgeInsets const kOnboardingContinueButtonPadding = {
  10, 20, 10, 20
};

@interface SEAOnboardingContentViewController ()

@property (nonatomic) NSString *titleText;
@property (nonatomic) NSString *subtitleText;
@property (nonatomic) UIImage *image;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIButton *continueButton;
@property (nonatomic) BOOL showButton;

@end

@implementation SEAOnboardingContentViewController

#pragma mark Initialization

- (instancetype)initWithTitleText:(NSString *)titleText subtitleText:(NSString *)subtitleText image:(UIImage *)image showButton:(BOOL)showButton {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.titleText = titleText;
  self.subtitleText = subtitleText;
  self.image = image;
  self.showButton = showButton;
  self.viewWillAppearBlock = ^{};
  self.viewDidAppearBlock = ^{};

  return self;
}

#pragma mark View

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.delegate) {
    [self.delegate setUpcomingPage:self];
  }

  self.viewWillAppearBlock();
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (self.delegate) {
    [self.delegate setCurrentPage:self];
  }

  self.viewDidAppearBlock();
}

- (void)setUpView {
  self.view.backgroundColor = self.backgroundColor;

  self.imageView = [[UIImageView alloc] initWithImage:self.image];
  CGFloat imageHeightRatio = self.image.size.height / self.image.size.width;
  self.imageView.width = MIN(self.view.width, self.imageView.width);
  self.imageView.height = self.imageView.width * imageHeightRatio;
  self.imageView.centerX = self.view.centerX;
  self.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self.view addSubview:self.imageView];

  self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kOnboardingWindowPadding, self.imageView.bottom + kOnboardingTitleLabelTopMargin, self.view.width - kOnboardingWindowPadding * 2, 0)];
  self.titleLabel.text = self.titleText;
  self.titleLabel.textColor = self.titleColor;
  self.titleLabel.font = [UIFont regularFontWithSize:self.titleFontSize];
  self.titleLabel.numberOfLines = 0;
  [self.titleLabel setFrameToFitWithHeightLimit:0];

  self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kOnboardingWindowPadding, self.titleLabel.bottom + kOnboardingLabelSpacing, self.view.width - kOnboardingWindowPadding * 2, 0)];
  self.subtitleLabel.text = self.subtitleText;
  self.subtitleLabel.textColor = self.subtitleColor;
  self.subtitleLabel.font = [UIFont regularFontWithSize:self.subtitleFontSize];
  self.subtitleLabel.numberOfLines = 0;
  [self.subtitleLabel setFrameToFitWithHeightLimit:0];

  for (UILabel *label in @[self.titleLabel, self.subtitleLabel]) {
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
  }

  if (self.showButton) {
    self.continueButton = [UIButton new];
    self.continueButton.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    [self.continueButton setTitleColor:self.continueButtonColor forState:UIControlStateNormal];
    self.continueButton.layer.borderColor = self.continueButtonColor.CGColor;
    self.continueButton.layer.borderWidth = 1;
    [self.continueButton setTitle:NSLocalizedString(@"Продолжить", nil) forState:UIControlStateNormal];
    CGSize continueButtonSize = [self.continueButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.continueButton.titleLabel.font }];
    continueButtonSize = CGSizeMake(kOnboardingContinueButtonPadding.left + continueButtonSize.width + kOnboardingContinueButtonPadding.right, kOnboardingContinueButtonPadding.top + continueButtonSize.height + kOnboardingContinueButtonPadding.bottom);
    self.continueButton.frame = CGRectMake((self.view.width - continueButtonSize.width) / 2, self.subtitleLabel.bottom + kOnboardingContinueButtonTopMargin, continueButtonSize.width, continueButtonSize.height);
    self.continueButton.clipsToBounds = YES;
    self.continueButton.layer.cornerRadius = continueButtonSize.height / 2;
    [self.continueButton setBackgroundImage:[UIImage imageWithColor:[self.continueButtonColor colorWithAlphaComponent:0.1f]] forState:UIControlStateHighlighted];
    [self.continueButton addTarget:self action:@selector(continueButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.continueButton];
  }

  CGFloat totalHeight = (self.showButton ? self.continueButton.bottom : self.subtitleLabel.bottom) - self.imageView.top;
  CGFloat diff = (self.view.height - kOnboardingBottomHeight - totalHeight + (self.isNewFeature ? kOnboardingTopHeight : 0)) / 2;

  for (UIView *view in @[self.imageView, self.titleLabel, self.subtitleLabel]) {
    view.top += diff;
  }

  if (self.showButton) {
    self.continueButton.top += diff;
  }
}

- (void)continueButtonTapped {
  [self.delegate performCompletionHandler];
}

#pragma mark Alpha

- (void)updateAlpha:(CGFloat)newAlpha {
  self.titleLabel.alpha = newAlpha;
  self.subtitleLabel.alpha = newAlpha;
  if (self.showButton) {
    self.continueButton.alpha = newAlpha;
  }
}

@end
