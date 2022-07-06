#import "SEAPromptView.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"

static CGFloat const kPromptViewButtonHeight = 30;
static CGFloat const kPromptViewButtonSpacing = 10;
static CGFloat const kPromptViewLabelBottomMargin = 10;
static NSString *const kInteractionKey = @"promptViewInteraction";
static UIEdgeInsets const kPromptViewPadding = {
  10, 10, 10, 10
};

@interface SEAPromptView ()

@property (nonatomic) BOOL liked;
@property (nonatomic) BOOL step2;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIButton *leftButton;
@property (nonatomic) UIButton *rightButton;
@property (nonatomic) UILabel *label;
@property (nonatomic) UIView *container;

@end

@implementation SEAPromptView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  [self setUpView];

  return self;
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.label.frame = CGRectMake(kPromptViewPadding.left, kPromptViewPadding.top, self.width - kPromptViewPadding.left - kPromptViewPadding.right, 0);
  [self.label setFrameToFitWithHeightLimit:0];
  self.leftButton.frame = CGRectMake(kPromptViewPadding.left, self.label.bottom + kPromptViewLabelBottomMargin, (self.width - kPromptViewPadding.left - kPromptViewButtonSpacing - kPromptViewPadding.right) / 2, kPromptViewButtonHeight);
  self.rightButton.frame = CGRectMake(self.leftButton.right + kPromptViewButtonSpacing, self.leftButton.top, self.leftButton.width, kPromptViewButtonHeight);
  self.height = self.rightButton.bottom + kPromptViewPadding.bottom;
  self.bottom = self.superview.bottom;
}

#pragma mark Public

+ (BOOL)hasHadInteractionForCurrentVersion {
  return [[NSUserDefaults standardUserDefaults] boolForKey:[self keyForCurrentVersion]];
}

+ (void)setHasHadInteractionForCurrentVersion {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[self keyForCurrentVersion]];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Private

- (void)setUpView {
  self.label = [UILabel new];
  self.label.textColor = [UIColor colorWithHexString:kOnyxColor];
  self.label.textAlignment = NSTextAlignmentCenter;
  self.label.numberOfLines = 0;
  self.label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.label.text = NSLocalizedString(@"Что вы думаете о Сеансах?", nil);
  [self addSubview:self.label];

  self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.leftButton.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.leftButton.layer.cornerRadius = 4;
  self.leftButton.layer.masksToBounds = YES;
  [self.leftButton setTitle:NSLocalizedString(@"Мне нравится!", nil) forState:UIControlStateNormal];
  [self.leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.leftButton.titleLabel.font = [UIFont systemFontOfSize:15];
  [self.leftButton addTarget:self action:@selector(onLove) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.leftButton];

  self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.rightButton.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.rightButton.layer.cornerRadius = 4;
  self.rightButton.layer.masksToBounds = YES;
  [self.rightButton setTitle:NSLocalizedString(@"Так себе", nil) forState:UIControlStateNormal];
  [self.rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.rightButton.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  [self.rightButton addTarget:self action:@selector(onImprove) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.rightButton];

  [self layoutIfNeeded];
}

- (void)onLove {
  if (self.step2) {
    [[self class] setHasHadInteractionForCurrentVersion];
    if (self.liked && self.delegate) {
      [self.delegate promptForReview];
    } else if (!self.liked && self.delegate) {
      [self.delegate promptForFeedback];
    }
  } else {
    self.liked = YES;
    self.step2 = YES;
    [UIView animateWithDuration:0.3f animations:^{
      self.label.text = NSLocalizedString(@"Отлично! Может быть тогда оставите нам отзыв? :)", nil);
      [self.leftButton setTitle:NSLocalizedString(@"Оставить отзыв", nil) forState:UIControlStateNormal];
      [self.rightButton setTitle:NSLocalizedString(@"Нет, спасибо", nil) forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
      [UIView animateWithDuration:0.3f animations:^{
        [self layoutSubviews];
      }];
    }];
  }
}

- (void)onImprove {
  if (self.step2) {
    [[self class] setHasHadInteractionForCurrentVersion];
    if (self.delegate) {
      [self.delegate promptClose];
    }
  } else {
    self.liked = NO;
    self.step2 = YES;
    [UIView animateWithDuration:0.3f animations:^{
      self.label.text = NSLocalizedString(@"Может быть скажете, как нам стать лучше?", nil);
      [self.leftButton setTitle:NSLocalizedString(@"Отправить отзыв", nil) forState:UIControlStateNormal];
      [self.rightButton setTitle:NSLocalizedString(@"Нет, спасибо", nil) forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
      [UIView animateWithDuration:0.3f animations:^{
        [self layoutSubviews];
      }];
    }];
  }
}

#pragma mark Helpers

+ (NSString *)keyForCurrentVersion {
  NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ? : NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
  return [kInteractionKey stringByAppendingString:version];
}

@end
