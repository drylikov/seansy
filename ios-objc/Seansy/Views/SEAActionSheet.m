#import "SEAActionSheet.h"

#import "SEAConstants.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import "UIWindow+SEAHelpers.h"

// How much user has to scroll beyond the top of the tableView for the view to dismiss automatically.
static CGFloat const kActionSheetAutoDismissOffset = 80;
// Length of the range at which the blurred background is being hidden when the user scrolls the tableView to the top.
static CGFloat const kActionSheetBlurFadeRangeSize = 200;
// Cancel button's shadow height as the ratio to the cancel button's height
static CGFloat const kActionSheetCancelButtonShadowHeightRatio = 0.3f;
// Offset at which there's a check if the user is flicking the tableView down.
static CGFloat const kActionSheetFlickDownHandlingOffset = 20;
static CGFloat const kActionSheetFlickDownMinVelocity = 2000;
// How much free space to leave at the top (above the tableView's contents) when there's a lot of elements.
// It makes this control look similar to the UIActionSheet.
static CGFloat const kActionSheetTopSpaceMarginFraction = 0.3f;
static NSTimeInterval const kActionSheetAnimationDuration = 0.4f;
static UIEdgeInsets const kActionSheetHeaderViewLabelPadding = {
  10, 15, 10, 15
};

@interface SEAActionSheetItem : NSObject

@property (copy, nonatomic) SEADismissHandler handler;
@property (copy, nonatomic) NSString *title;
@property (nonatomic) UIImage *image;
@property (nonatomic) UIView *view;

@end

@implementation SEAActionSheetItem
@end


@interface SEAActionSheetViewController : UIViewController

@property (nonatomic) SEAActionSheet *actionSheet;

@end

@implementation SEAActionSheetViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view addSubview:_actionSheet];
  self.actionSheet.frame = self.view.bounds;
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  self.actionSheet.frame = self.view.bounds;
}

@end


@interface SEAActionSheet () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *items;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UIImageView *backgroundView;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIView *cancelButtonShadowView;
@property (nonatomic) UIWindow *window;
@property (weak, nonatomic) UIWindow *previousKeyWindow;

@end

@implementation SEAActionSheet

#pragma mark Initialization

- (instancetype)initWithTitle:(NSString *)title {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.title = [title copy];
  NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
  paragraphStyle.alignment = NSTextAlignmentCenter;
  self.titleTextAttributes = @{
    NSFontAttributeName : [UIFont lightFontWithSize:[UIFont actionSheetTitleFontSize]],
    NSParagraphStyleAttributeName : paragraphStyle,
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  self.buttonTextAttributes = @{
    NSFontAttributeName : [UIFont regularFontWithSize:[UIFont actionSheetButtonFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };

  self.activeIndex = NSNotFound;
  self.staticIndex = NSNotFound;
  self.disabledIndex = NSNotFound;
  self.animationDuration = kActionSheetAnimationDuration;
  self.automaticallyTintButtonImages = YES;
  self.buttonHeight = 50;
  self.buttonTextCenteringEnabled = NO;
  self.cancelButtonTitle = NSLocalizedString(@"Назад", nil);
  self.cancelOnPanGestureEnabled = YES;
  self.selectedBackgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
  self.separatorColor = [UIColor colorWithWhite:1 alpha:0.25f];

  self.items = [NSMutableArray new];

  return self;
}

#pragma mark Public

- (void)addButtonWithTitle:(NSString *)title handler:(SEADismissHandler)handler {
  [self addButtonWithTitle:title image:nil handler:handler];
}

- (void)addButtonWithTitle:(NSString *)title image:(UIImage *)image handler:(SEADismissHandler)handler {
  SEAActionSheetItem *item = [SEAActionSheetItem new];

  item.title = title;
  item.image = image;
  item.handler = handler;
  [self.items addObject:item];
}

- (void)addView:(UIView *)view {
  SEAActionSheetItem *item = [SEAActionSheetItem new];

  item.view = view;
  [self.items addObject:item];
}

- (void)show {
  if ([self isVisible]) {
    return;
  }

  self.previousKeyWindow = [UIApplication sharedApplication].keyWindow;
  UIImage *previousKeyWindowSnapshot = [self.previousKeyWindow snapshot];
  [self setUpNewWindow];
  [self setUpBackgroundWithSnapshot:previousKeyWindowSnapshot];
  [self setUpCancelButton];
  [self setUpTableView];

  CGFloat slideDownMinOffset = (CGFloat)fmin(self.height + self.tableView.contentOffset.y, self.height);
  self.tableView.transform = CGAffineTransformMakeTranslation(0, slideDownMinOffset);

  void (^immediateAnimations)(void) = ^{
    self.backgroundView.alpha = 1;
  };

  void (^delayedAnimations)(void) = ^{
    self.cancelButton.frame = CGRectMake(0, self.height - self.buttonHeight, self.width, self.buttonHeight);
    self.tableView.transform = CGAffineTransformIdentity;

    // Manual calculation of table's contentSize.height
    CGFloat tableContentHeight = self.tableView.tableHeaderView.height;
    for (SEAActionSheetItem *item in self.items) {
      if (item.view) {
        tableContentHeight += item.view.height;
      } else {
        tableContentHeight += self.buttonHeight;
      }
    }

    CGFloat topInset;
    BOOL buttonsFitInWithoutScrolling = tableContentHeight < self.tableView.height * (1 - kActionSheetTopSpaceMarginFraction);
    if (buttonsFitInWithoutScrolling) {
      // show all buttons if there isn't many
      topInset = self.tableView.height - tableContentHeight;
    } else {
      // leave an empty space on the top to make the control look similar to UISEAActionSheet
      topInset = (CGFloat)round(self.tableView.height * kActionSheetTopSpaceMarginFraction);
    }

    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    self.tableView.bounces = self.cancelOnPanGestureEnabled || buttonsFitInWithoutScrolling;
  };

  [UIView animateKeyframesWithDuration:self.animationDuration delay:0 options:0 animations:^{
    immediateAnimations();
    [UIView addKeyframeWithRelativeStartTime:0.3f relativeDuration:0.7f animations:^{
      delayedAnimations();
    }];
  } completion:nil];
}

- (void)dismissAnimated:(BOOL)animated {
  [self dismissAnimated:animated duration:self.animationDuration handler:self.dismissHandler];
}

- (void)dismissAnimated:(BOOL)animated handler:(SEADismissHandler)handler {
  [self dismissAnimated:animated duration:self.animationDuration handler:handler];
}

#pragma mark Private

- (BOOL)isVisible {
  // Action sheet is visible if it's associated with a window
  return !!self.window;
}

- (void)dismissAnimated:(BOOL)animated duration:(NSTimeInterval)duration handler:(SEADismissHandler)handler {
  if (![self isVisible]) {
    return;
  }

  // Delegate isn't needed anymore because tableView will be hidden
  // (and we don't want delegate methods to be called now)
  self.tableView.delegate = nil;
  self.tableView.userInteractionEnabled = NO;
  // Keep the table from scrolling back up
  self.tableView.contentInset = UIEdgeInsetsMake(-self.tableView.contentOffset.y, 0, 0, 0);

  void (^tearDownView)(void) = ^{
    NSArray *views = @[self.tableView, self.cancelButton, self.backgroundView, self.window];
    [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.window = nil;
    [self.previousKeyWindow makeKeyAndVisible];
    if (handler) {
      handler();
    }
  };

  if (animated) {
    // Animate sliding down tableView and cancelButton
    [UIView animateWithDuration:duration animations:^{
      self.backgroundView.alpha = 0;
      self.cancelButton.transform = CGAffineTransformTranslate(self.cancelButton.transform, 0, self.buttonHeight);
      self.cancelButtonShadowView.alpha = 0;

      // Shortest shift of position sufficient to hide all tableView contents below the bottom margin.
      // contentInset isn't used here because it caused weird problems with animations in some cases.
      CGFloat slideDownMinOffset = (CGFloat)fmin(self.height + self.tableView.contentOffset.y, self.height);
      self.tableView.transform = CGAffineTransformMakeTranslation(0, slideDownMinOffset);
    } completion:^(BOOL finished) {
      tearDownView();
    }];
  } else {
    tearDownView();
  }
}

- (void)setUpNewWindow {
  SEAActionSheetViewController *actionSheetViewController = [SEAActionSheetViewController new];

  actionSheetViewController.actionSheet = self;

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.window.opaque = NO;
  self.window.rootViewController = actionSheetViewController;
  [self.window makeKeyAndVisible];
}

- (void)setUpBackgroundWithSnapshot:(UIImage *)previousKeyWindowSnapshot {
  UIImage *blurredViewSnapshot = [previousKeyWindowSnapshot applyBlurWithRadius:kModalViewBlurRadius tintColor:[UIColor colorWithWhite:0 alpha:kModalViewBlurDarkeningRatio] saturationDeltaFactor:kModalViewBlurSaturationDeltaFactor maskImage:nil];
  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:blurredViewSnapshot];

  backgroundView.frame = self.bounds;
  backgroundView.alpha = 0;
  [self addSubview:backgroundView];

  self.backgroundView = backgroundView;
}

- (void)setUpCancelButton {
  UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];

  [cancelButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.cancelButtonTitle attributes:self.buttonTextAttributes] forState:UIControlStateNormal];
  [cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  cancelButton.frame = CGRectMake(0, self.height - self.buttonHeight, self.width, self.buttonHeight);
  // Move the button below the screen (ready to be animated -show)
  cancelButton.transform = CGAffineTransformMakeTranslation(0, self.buttonHeight);
  [self addSubview:cancelButton];

  self.cancelButton = cancelButton;

  // Add a small shadow/glow above the button
  if (self.cancelButtonShadowColor) {
    self.cancelButton.clipsToBounds = NO;
    CGFloat gradientHeight = (CGFloat)round(self.buttonHeight * kActionSheetCancelButtonShadowHeightRatio);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, -gradientHeight, self.width, gradientHeight)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    gradient.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor colorWithWhite:0 alpha:0.1f].CGColor];
    [view.layer insertSublayer:gradient atIndex:0];
    [self.cancelButton addSubview:view];

    self.cancelButtonShadowView = view;
  }
}

- (void)setUpTableView {
  CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);

  self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, statusBarHeight, self.width, self.height - statusBarHeight - self.buttonHeight)];
  self.tableView.backgroundColor = [UIColor clearColor];
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.tableFooterView = [UIView new];
  self.tableView.separatorInset = UIEdgeInsetsZero;
  if (self.separatorColor) {
    self.tableView.separatorColor = self.separatorColor;
  }

  // Move the content below the screen, ready to be animated in -show
  self.tableView.contentInset = UIEdgeInsetsMake(self.height, 0, 0, 0);

  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
  [self insertSubview:self.tableView aboveSubview:self.backgroundView];

  [self setUpTableViewHeader];
}

- (void)setUpTableViewHeader {
  if (self.title) {
    // Create a label and calculate its size
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kActionSheetHeaderViewLabelPadding.left, kActionSheetHeaderViewLabelPadding.top, self.width - kActionSheetHeaderViewLabelPadding.left - kActionSheetHeaderViewLabelPadding.right, 0)];
    label.numberOfLines = 0;
    label.attributedText = [[NSAttributedString alloc] initWithString:self.title attributes:self.titleTextAttributes];
    [label setFrameToFitWithHeightLimit:0];

    // Create and add a header consisting of the label
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, label.height + kActionSheetHeaderViewLabelPadding.top + kActionSheetHeaderViewLabelPadding.bottom)];
    [headerView addSubview:label];
    self.tableView.tableHeaderView = headerView;
  } else if (self.headerView) {
    self.tableView.tableHeaderView = self.headerView;
  }

  // Add a separator between the tableHeaderView and a first row (technically at the bottom of the tableHeaderView)
  if (self.tableView.tableHeaderView && self.tableView.separatorStyle != UITableViewCellSeparatorStyleNone) {
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.tableHeaderView.height - 1 / [UIScreen mainScreen].scale, self.tableView.tableHeaderView.width, 1 / [UIScreen mainScreen].scale)];
    separator.backgroundColor = self.tableView.separatorColor;
    [self.tableView.tableHeaderView addSubview:separator];
  }
}

- (void)fadeBlursOnScrollToTop {
  if (self.tableView.isDragging || self.tableView.isDecelerating) {
    CGFloat alphaWithoutBounds = 1 - (-(self.tableView.contentInset.top + self.tableView.contentOffset.y) /  kActionSheetBlurFadeRangeSize);
    // Limit alpha to the interval [0, 1]
    CGFloat alpha = (CGFloat)fmax(fmin(alphaWithoutBounds, 1), 0);
    self.backgroundView.alpha = alpha;
    self.cancelButtonShadowView.alpha = alpha;
  }
}

- (void)cancelButtonTapped:(id)sender {
  [self dismissAnimated:YES handler:self.dismissHandler];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];

  cell.backgroundColor = [UIColor clearColor];

  SEAActionSheetItem *item = self.items[(NSUInteger)indexPath.row];

  if (!item.view) {
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:item.title attributes:self.buttonTextAttributes];
    cell.textLabel.textAlignment = self.buttonTextCenteringEnabled ? NSTextAlignmentCenter : NSTextAlignmentLeft;

    // Use image with template mode with color the same as the text (when enabled)
    BOOL useTemplateMode = [UIImage instancesRespondToSelector:@selector(imageWithRenderingMode:)] && self.automaticallyTintButtonImages;
    if (useTemplateMode) {
      cell.imageView.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      cell.imageView.tintColor = (UIColor *)self.buttonTextAttributes[NSForegroundColorAttributeName];
    } else {
      cell.imageView.image = item.image;
    }

    if ((NSInteger)self.activeIndex == indexPath.row || (NSInteger)self.staticIndex == indexPath.row) {
      UIImageView *checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(cell.width - 30, (cell.height - 20) / 2, 20, 20)];
      checkIcon.image = [[UIImage imageNamed:@"CheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      checkIcon.tintColor = [UIColor whiteColor];
      [cell addSubview:checkIcon];

      if ((NSInteger)self.staticIndex == indexPath.row) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.alpha = kDisabledAlpha;
        cell.imageView.alpha = kDisabledAlpha;
        checkIcon.alpha = kDisabledAlpha;
      }
    } else if ((NSInteger)self.disabledIndex == indexPath.row) {
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.alpha = kDisabledAlpha;
      cell.imageView.alpha = kDisabledAlpha;
    }

    cell.selectedBackgroundView = [UIView new];
    cell.selectedBackgroundView.backgroundColor = self.selectedBackgroundColor;
  } else {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell addSubview:item.view];
  }

  return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SEAActionSheetItem *item = self.items[(NSUInteger)indexPath.row];

  if (!item.view && indexPath.row != (NSInteger)self.staticIndex && indexPath.row != (NSInteger)self.disabledIndex) {
    [self dismissAnimated:YES handler:item.handler];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  SEAActionSheetItem *item = self.items[(NSUInteger)indexPath.row];

  if (!item.view) {
    return self.buttonHeight;
  } else {
    return item.view.height;
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  // Remove seperator inset
  if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
    [cell setSeparatorInset:UIEdgeInsetsZero];
  }

  // Prevent the cell from inheriting the Table View's margin settings
  if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
    [cell setPreservesSuperviewLayoutMargins:NO];
  }

  // Explictly set your cell's layout margins
  if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
    [cell setLayoutMargins:UIEdgeInsetsZero];
  }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (!self.cancelOnPanGestureEnabled) {
    return;
  }

  [self fadeBlursOnScrollToTop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!self.cancelOnPanGestureEnabled) {
    return;
  }

  CGPoint scrollVelocity = [scrollView.panGestureRecognizer velocityInView:self];

  BOOL viewWasFlickedDown = scrollVelocity.y > kActionSheetFlickDownMinVelocity && scrollView.contentOffset.y < -self.tableView.contentInset.top - kActionSheetFlickDownHandlingOffset;
  BOOL shouldSlideDown = scrollView.contentOffset.y < -self.tableView.contentInset.top - kActionSheetAutoDismissOffset;

  if (viewWasFlickedDown) {
    [self dismissAnimated:YES duration:0.2f handler:self.dismissHandler];
  } else if (shouldSlideDown) {
    [self dismissAnimated:YES handler:self.dismissHandler];
  }
}

@end
