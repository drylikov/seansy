#import "SEANewsEntryCell.h"

#import "NSDate+SEAHelpers.h"
#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <GTMNSStringHTMLAdditions/GTMNSString+HTML.h>
#import <SDWebImage/UIImageView+WebCache.h>

UIEdgeInsets const kNewsEntryCellPadding = {
  10, 10, 10, 10
};
CGFloat kNewsEntryCellTitleTopMargin = 10;

@interface SEANewsEntryCell ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIView *overlayView;

@end

@implementation SEANewsEntryCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];
  self.parallaxImage.backgroundColor = [UIColor clearColor];
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  self.overlayView = [UIView new];
  self.overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];

  self.subtitleLabel = [UILabel new];
  self.subtitleLabel.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
  self.subtitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75f];

  self.titleLabel = [UILabel new];
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.numberOfLines = 0;

  [self.contentView addSubview:self.overlayView];
  [self.contentView addSubview:self.subtitleLabel];
  [self.contentView addSubview:self.titleLabel];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  self.parallaxImage.image = nil;
  self.overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
  self.titleLabel.text = @"";
  self.subtitleLabel.text = @"";
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.overlayView.frame = self.bounds;
  self.subtitleLabel.frame = CGRectMake(kNewsEntryCellPadding.left, kNewsEntryCellPadding.top, self.width - kNewsEntryCellPadding.left - kNewsEntryCellPadding.right, 0);
  [self.subtitleLabel setFrameToFitWithHeightLimit:0];
  self.titleLabel.frame = CGRectMake(kNewsEntryCellPadding.left, self.subtitleLabel.bottom + kNewsEntryCellTitleTopMargin, self.width - kNewsEntryCellPadding.left - kNewsEntryCellPadding.right, 0);
  self.titleLabel.font = [UIFont lightFontWithSize:[UIFont newsEntryTitleFontSize]];
  [self.titleLabel adjustFontSizeWithMaxLines:3 fontFloor:[UIFont largeTextFontSize]];
  CGFloat diff = (kNewsEntryCellHeight - self.titleLabel.bottom - kNewsEntryCellPadding.bottom) / 2;
  for (UILabel *label in @[self.subtitleLabel, self.titleLabel]) {
    label.top += diff;
  }
}

#pragma mark Setters

- (void)setNewsEntry:(SEANewsEntry *)newsEntry {
  _newsEntry = newsEntry;

  self.titleLabel.text = [[newsEntry.title gtm_stringByUnescapingFromHTML] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.subtitleLabel.text = [NSString stringWithFormat:@"%@ • %@", [[newsEntry.link host] stringByReplacingOccurrencesOfString:@"www." withString:@""], [newsEntry.date timeAgo]];
  [self setNeedsLayout];

  [self.parallaxImage sd_setImageWithURL:newsEntry.imageUrl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    if (cacheType == SDImageCacheTypeNone) {
      self.parallaxImage.alpha = 0;
      [UIView animateWithDuration:0.3f animations:^{
        self.parallaxImage.alpha = 1;
      }];
    }
  }];
}

- (void)setHighlighted:(BOOL)highlighted {
  self.overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:highlighted ? 0.75f : 0.5f];
}

@end
