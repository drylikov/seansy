#import "SEAErrorView.h"

#import "UIFont+SEASizes.h"
#import "UIColor+SEAHelpers.h"
#import "SEAConstants.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"

@interface SEAErrorView ()

@property (nonatomic) UIButton *reloadButton;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;
@property (nonatomic) UIView *contentView;
@property (copy, nonatomic) SEAErrorViewReloadBlock reloadBlock;

@end

@implementation SEAErrorView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text {
  return [self initWithFrame:frame image:image text:text reloadBlock:nil];
}

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text reloadBlock:(SEAErrorViewReloadBlock)reloadBlock {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }
  self.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.verticalOffset = 0;

  self.imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
  self.imageView.tintColor = [UIColor whiteColor];

  _text = text;
  self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.bottom + 20, self.width - 100, 0)];
  self.label.text = text;
  self.label.textColor = [UIColor whiteColor];
  self.label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.label.textAlignment = NSTextAlignmentCenter;
  self.label.numberOfLines = 0;

  self.reloadBlock = reloadBlock;
  if (self.reloadBlock) {
    self.reloadButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [self.reloadButton setImage:[[UIImage imageNamed:@"ReloadIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.reloadButton.tintColor = [UIColor whiteColor];
    [self.reloadButton addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
  }

  self.contentView = [UIView new];

  [self.contentView addSubview:self.imageView];
  [self.contentView addSubview:self.label];
  [self.contentView addSubview:self.reloadButton];

  [self addSubview:self.contentView];

  return self;
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  [self.label setFrameToFitWithHeightLimit:0];
  self.imageView.top = 0;
  self.imageView.centerX = self.width / 2;
  self.label.centerX = self.width / 2;
  self.reloadButton.top = self.label.bottom + 20;
  self.reloadButton.centerX = self.width / 2;
  self.contentView.frame = CGRectMake(0, 0, self.width, self.reloadButton ? self.reloadButton.bottom : self.label.bottom);
  self.contentView.centerY = self.height / 2 + self.verticalOffset;
}

#pragma mark Setters

- (void)setText:(NSString *)text {
  _text = text;
  self.label.text = text;
}

#pragma mark Private

- (void)reload {
  if (self.reloadBlock) {
    self.reloadBlock();
  }
}

@end
