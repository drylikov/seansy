#import "SEAReviewsCarouselCell.h"

#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"

static UIOffset const kReviewsCarouselCellPadding = {
  10, 10
};
static CGFloat const kReviewsCarouselCellIconViewWidth = 50;

@interface SEAReviewsCarouselCell ()

@property (nonatomic) UILabel *textLabel;
@property (nonatomic) UIScrollView *textScrollView;
@property (nonatomic) UIView *textScrollViewWrapper;
@property (nonatomic) UIView *iconBackgroundView;
@property (nonatomic) UIImageView *iconView;

@end

@implementation SEAReviewsCarouselCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.contentView.layer.borderWidth = 2;
  self.opaque = NO;

  self.iconBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kReviewsCarouselCellIconViewWidth, self.height)];
  self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
  self.iconView.center = self.iconBackgroundView.center;
  self.iconView.tintColor = [UIColor whiteColor];

  self.textScrollViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(self.iconBackgroundView.right, 0, self.width - self.iconBackgroundView.right, self.height)];
  self.textScrollView = [[UIScrollView alloc] initWithFrame:self.textScrollViewWrapper.bounds];
  self.textLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.textScrollView.bounds, kReviewsCarouselCellPadding.horizontal, kReviewsCarouselCellPadding.vertical)];
  self.textLabel.textColor = [UIColor whiteColor];
  self.textLabel.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
  self.textLabel.numberOfLines = 0;
  [self.textScrollViewWrapper addSubview:self.textScrollView];
  [self.textScrollView addSubview:self.textLabel];

  [self.contentView addSubview:self.iconBackgroundView];
  [self.contentView addSubview:self.iconView];
  [self.contentView addSubview:self.textScrollViewWrapper];

  return self;
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.iconBackgroundView.height = self.height;
  self.iconView.center = self.iconBackgroundView.center;
  [self.textLabel setFrameToFitWithHeightLimit:0];
  self.textScrollView.contentSize = CGSizeMake(self.textScrollView.width, self.textLabel.height + kReviewsCarouselCellPadding.vertical * 2);
  if (self.textScrollView.contentSize.height - 1 > self.textScrollView.height) {
    self.textScrollView.contentInset = UIEdgeInsetsMake(0, 0, 20, 0);
    self.textScrollViewWrapper.layer.mask = [self createBottomMaskWithSize:self.textScrollViewWrapper.size startFadeAt:self.textScrollViewWrapper.height - 20 endAt:self.textScrollViewWrapper.height topColor:[UIColor whiteColor] botColor:[UIColor clearColor]];
  } else {
    self.textScrollView.contentInset = UIEdgeInsetsZero;
    self.textScrollViewWrapper.layer.mask = nil;
  }
}

- (void)drawRect:(CGRect)rect { }

#pragma mark UICollectionReusableView

- (void)prepareForReuse {
  [super prepareForReuse];
  self.textLabel.text = @"";
}

#pragma mark Setters

- (void)setReview:(NSDictionary *)review {
  _review = review;
  BOOL isPositive = [review[@"type"] isEqualToString:@"positive"];
  self.iconView.image = [[UIImage imageNamed:isPositive ? @"LikeIcon" : @"DislikeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.iconBackgroundView.backgroundColor = isPositive ? [UIColor colorWithHexString:kGreenColor] : [UIColor colorWithHexString:kRedColor];
  self.contentView.layer.borderColor = self.iconBackgroundView.backgroundColor.CGColor;
  self.textLabel.text = review[@"text"];
}

#pragma mark Public

+ (CGSize)sizeForText:(NSString *)text {
  NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  return CGSizeMake(kReviewsCarouselCellWidth, [text boundingRectWithSize:CGSizeMake(kReviewsCarouselCellWidth - kReviewsCarouselCellPadding.horizontal * 2 - kReviewsCarouselCellIconViewWidth, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{
                                                  NSParagraphStyleAttributeName : paragraphStyle.copy,
                                                  NSFontAttributeName : [UIFont regularFontWithSize:[UIFont smallTextFontSize]]
                                                } context:nil].size.height + kReviewsCarouselCellPadding.vertical * 2);
}

#pragma mark Private

- (CALayer *)createBottomMaskWithSize:(CGSize)size startFadeAt:(CGFloat)top endAt:(CGFloat)bottom topColor:(UIColor *)topColor botColor:(UIColor *)botColor; {
  top /= size.height;
  bottom /= size.height;
  
  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  maskLayer.anchorPoint = CGPointZero;
  maskLayer.startPoint = CGPointMake(0.5f, 0);
  maskLayer.endPoint = CGPointMake(0.5f, 1);
  
  maskLayer.colors = @[(id)topColor.CGColor, (id)topColor.CGColor, (id)botColor.CGColor, (id)botColor.CGColor];
  maskLayer.locations = @[@0, @(top), @(bottom), @1];
  maskLayer.frame = CGRectMake(0, 0, size.width, size.height);
  
  return maskLayer;
}

@end
