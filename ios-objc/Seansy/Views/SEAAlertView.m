//
//  Copyright (c) 2014 AnyKey Entertainment, 2015 Ayan Yenbekbay.
//

#import "SEAAlertView.h"

#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UIImage+SEAHelpers.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import "UIWindow+SEAHelpers.h"

static CGFloat const kAlertImageWidth = 180;
static CGFloat const kAlertViewContentViewCornerRadius = 5;
static CGFloat const kAlertViewWidth = 240;
static CGFloat kAlertViewBodyLabelTopMargin = 10;
static CGFloat kAlertViewButtonHeight = 50;
static CGFloat kAlertViewButtonsTopMargin = 15;
static CGFloat kAlertViewTitleLabelHeightLimit = 40;
static NSString *const kAlertViewPushAnimationKey = @"alertViewPush";
static UIEdgeInsets const kAlertViewContentViewPadding = {
  15, 10, 0, 10
};

@interface SEAAlertViewButton : UIButton

@property (copy, nonatomic) SEADismissHandler handler;
@property (copy, nonatomic) NSString *title;

@end

@implementation SEAAlertViewButton
@end


@interface SEAAlertViewController : UIViewController

@property (nonatomic) SEAAlertView *alertView;

@end

@implementation SEAAlertViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view addSubview:self.alertView];
  self.alertView.frame = self.view.bounds;
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  self.alertView.frame = self.view.bounds;
}

@end


@interface SEAAlertView () <UIGestureRecognizerDelegate>

@property (nonatomic) CGFloat contentHeight;
@property (nonatomic) CGFloat contentWidth;
@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) UIImageView *backgroundView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *bodyLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *bodyView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIWindow *window;
@property (weak, nonatomic) UIWindow *previousKeyWindow;

@end

@implementation SEAAlertView

#pragma mark Initialization

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body {
  return [self initWithTitle:title body:body closeButtonTitle:NSLocalizedString(@"ОК", nil) handler:nil];
}

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body closeButtonTitle:(NSString *)closeButtonTitle {
  return [self initWithTitle:title body:body closeButtonTitle:closeButtonTitle handler:nil];
}

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body closeButtonTitle:(NSString *)closeButtonTitle handler:(SEADismissHandler)handler {
  self = [super init];
  if (!self) {
    return nil;
  }

  NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
  paragraphStyle.alignment = NSTextAlignmentCenter;
  self.titleTextAttributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont largeTextFontSize]],
    NSParagraphStyleAttributeName : paragraphStyle,
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  self.bodyTextAttributes = @{
    NSFontAttributeName : [UIFont lightFontWithSize:[UIFont mediumTextFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  self.buttonTextAttributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont alertViewButtonFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  self.animationDuration = kModalViewAnimationDuration;
  self.contentWidth = kAlertViewWidth;
  self.contentViewColor = [UIColor colorWithHexString:kOnyxColor];
  self.dismissOnTapOutside = YES;

  self.title = title;
  self.body = body;
  self.closeButtonTitle = closeButtonTitle;
  self.buttons = [NSMutableArray new];

  return self;
}

- (instancetype)initWithView:(UIView *)view closeButtonTitle:(NSString *)closeButtonTitle {
  return [self initWithView:view closeButtonTitle:closeButtonTitle handler:nil];
}

- (instancetype)initWithView:(UIView *)view closeButtonTitle:(NSString *)closeButtonTitle handler:(SEADismissHandler)handler {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.buttonTextAttributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont alertViewButtonFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  self.animationDuration = kModalViewAnimationDuration;
  self.contentWidth = kAlertViewWidth;
  self.contentViewColor = [UIColor colorWithHexString:kOnyxColor];
  self.dismissOnTapOutside = YES;
  self.bodyView = view;
  self.closeButtonTitle = closeButtonTitle;
  self.buttons = [NSMutableArray new];

  return self;
}

#pragma mark Setters

- (void)setContentViewColor:(UIColor *)contentViewColor {
  _contentViewColor = contentViewColor;
  self.contentView.backgroundColor = self.contentViewColor;
}

#pragma mark Gesture recognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.dismissOnTapOutside) {
    for (UITouch *touch in touches) {
      CGPoint tappedPoint = [touch locationInView:self];
      if (!CGRectContainsPoint(self.contentView.frame, tappedPoint)) {
        [self dismissAnimated:YES handler:self.dismissHandler];
        break;
      }
    }
  }
}

#pragma mark Public

- (void)addButtonWithTitle:(NSString *)title handler:(SEADismissHandler)handler {
  SEAAlertViewButton *button = [SEAAlertViewButton new];

  button.title = title;
  button.handler = handler;
  [button setBackgroundImage:nil forState:UIControlStateNormal];
  [button setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithWhite:1 alpha:0.05f]] forState:UIControlStateHighlighted];
  [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.buttons addObject:button];
}

- (void)show {
  if ([self isVisible]) {
    return;
  }

  self.previousKeyWindow = [UIApplication sharedApplication].keyWindow;
  UIImage *previousKeyWindowSnapshot = [self.previousKeyWindow snapshot];
  [self setUpNewWindow];
  [self setUpBackgroundWithSnapshot:previousKeyWindowSnapshot];
  [self setUpContentView];

  self.contentView.top -= self.height;
  self.backgroundView.alpha = 0;

  [UIView animateWithDuration:self.animationDuration animations:^{
    self.contentView.top = (self.height - self.contentHeight) / 2;
    self.backgroundView.alpha = 1;
  }];
}

- (void)dismissAnimated:(BOOL)animated {
  [self dismissAnimated:animated handler:self.dismissHandler];
}

#pragma mark Private

- (void)setUpNewWindow {
  SEAAlertViewController *alertViewController = [SEAAlertViewController new];
  alertViewController.alertView = self;

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.window.opaque = NO;
  self.window.rootViewController = alertViewController;
  [self.window makeKeyAndVisible];
}

- (void)setUpBackgroundWithSnapshot:(UIImage *)previousKeyWindowSnapshot {
  UIImage *blurredViewSnapshot = [previousKeyWindowSnapshot applyBlurWithRadius:kModalViewBlurRadius tintColor:[UIColor colorWithWhite:0 alpha:kModalViewBlurDarkeningRatio] saturationDeltaFactor:kModalViewBlurSaturationDeltaFactor maskImage:nil];
  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:blurredViewSnapshot];

  backgroundView.frame = [UIScreen mainScreen].bounds;
  backgroundView.alpha = 0;
  [self addSubview:backgroundView];

  self.backgroundView = backgroundView;
}

- (void)setUpContentView {
  CGFloat offset = kAlertViewContentViewPadding.top;

  self.contentView = [UIView new];
  self.contentView.backgroundColor = self.contentViewColor;
  self.contentView.layer.cornerRadius = kAlertViewContentViewCornerRadius;
  self.contentView.layer.borderWidth = 1;
  self.contentView.layer.borderColor = [UIColor colorWithWhite:1 alpha:kDisabledAlpha].CGColor;
  self.contentView.layer.masksToBounds = YES;

  if (!self.bodyView) {
    if ([self.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
      self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewContentViewPadding.left, offset, self.contentWidth - kAlertViewContentViewPadding.left - kAlertViewContentViewPadding.right, 0)];
      self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.title attributes:self.titleTextAttributes];
      self.titleLabel.numberOfLines = 1;
      self.titleLabel.textAlignment = NSTextAlignmentCenter;
      [self.titleLabel setFrameToFitWithHeightLimit:kAlertViewTitleLabelHeightLimit];
      [self.contentView addSubview:self.titleLabel];
      offset += self.titleLabel.height + kAlertViewBodyLabelTopMargin;
    }

    if (self.image) {
      CGFloat imageHeightRatio = self.image.size.height / self.image.size.width;
      self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.contentWidth - kAlertImageWidth) / 2, offset, kAlertImageWidth, kAlertImageWidth * imageHeightRatio)];
      self.imageView.image = self.image;
      [self.contentView addSubview:self.imageView];
      offset += self.imageView.height + kAlertViewBodyLabelTopMargin;
    }

    if ([self.body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
      self.bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewContentViewPadding.left, offset, self.contentWidth - kAlertViewContentViewPadding.left - kAlertViewContentViewPadding.right, 0)];
      self.bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:self.body attributes:self.bodyTextAttributes];
      self.bodyLabel.numberOfLines = 0;
      self.bodyLabel.textAlignment = NSTextAlignmentCenter;
      [self.bodyLabel setFrameToFitWithHeightLimit:0];
      [self.contentView addSubview:self.bodyLabel];
      offset += self.bodyLabel.height + kAlertViewButtonsTopMargin;
    }
  } else {
    self.bodyView.frame = CGRectMake(0, offset, self.contentWidth, self.bodyView.height);
    [self.contentView addSubview:self.bodyView];
    offset += self.bodyView.height + kAlertViewButtonsTopMargin;
  }

  [self addButtonWithTitle:self.closeButtonTitle handler:self.dismissHandler];
  for (SEAAlertViewButton *button in self.buttons) {
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, offset, self.contentWidth, 1 / [UIScreen mainScreen].scale)];
    separator.backgroundColor = [UIColor colorWithWhite:1 alpha:kDisabledAlpha];
    [self.contentView addSubview:separator];
    offset += separator.height;

    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:button.title attributes:self.buttonTextAttributes] forState:UIControlStateNormal];
    NSDictionary *highlightedButtonTextAttributes = @{
      NSFontAttributeName : self.buttonTextAttributes[NSFontAttributeName],
      NSForegroundColorAttributeName : [(UIColor *)self.buttonTextAttributes[NSForegroundColorAttributeName] colorWithAlphaComponent:0.5f]
    };
    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:button.title attributes:highlightedButtonTextAttributes] forState:UIControlStateHighlighted];
    button.frame = CGRectMake(0, offset, self.contentWidth, kAlertViewButtonHeight);
    [button.titleLabel adjustsFontSizeToFitWidth];
    [self.contentView addSubview:button];
    offset += button.height;
  }

  self.contentHeight = offset;
  self.contentView.frame = CGRectMake((self.width - self.contentWidth) / 2, (self.height - self.contentHeight) / 2, self.contentWidth, self.contentHeight);
  [self addSubview:self.contentView];
}

- (BOOL)isVisible {
  // Alert view is visible if it's associated with a window
  return !!self.window;
}

- (void)buttonTapped:(SEAAlertViewButton *)button {
  [self dismissAnimated:YES handler:button.handler];
}

- (void)dismissAnimated:(BOOL)animated handler:(SEADismissHandler)handler {
  NSArray *views = @[self.contentView, self.backgroundView, self.window];

  if (animated) {
    [UIView animateWithDuration:self.animationDuration animations:^{
      self.contentView.top += self.backgroundView.height;
      self.backgroundView.alpha = 0;
    } completion:^(BOOL completed) {
      [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
      self.window = nil;
      [self.previousKeyWindow makeKeyAndVisible];
      if (handler) {
        handler();
      }
    }];
  } else {
    [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.window = nil;
    [self.previousKeyWindow makeKeyAndVisible];
    if (handler) {
      handler();
    }
  }
}

@end
