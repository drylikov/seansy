#import "SEAMoviesTableViewCell.h"

#import "NSString+SEAHelpers.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "UIColor+SEAHelpers.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

UIEdgeInsets const kMoviesTableViewCellPadding = {
  0, 10, 0, 10
};

@interface SEAMoviesTableViewCell ()

@property (nonatomic) UIImageView *poster;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;

@end

@implementation SEAMoviesTableViewCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  UIView *selectedBackgroundView = [UIView new];
  selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];
  self.selectedBackgroundView = selectedBackgroundView;

  self.poster = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kMoviesTableViewCellHeight * 0.7f, kMoviesTableViewCellHeight)];;
  self.poster.contentMode = UIViewContentModeScaleAspectFill;
  self.poster.clipsToBounds = YES;

  self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMoviesTableViewCellPadding.left + self.poster.right, 0, self.width - kMoviesTableViewCellPadding.left - kMoviesTableViewCellPadding.right - self.poster.right, 0)];
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightLight];

  self.subtitleLabel = [[UILabel alloc] initWithFrame:self.titleLabel.frame];
  self.subtitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75f];
  self.subtitleLabel.numberOfLines = 2;

  [self.contentView addSubview:self.poster];
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subtitleLabel];

  return self;
}

#pragma mark UITableViewCell

- (void)prepareForReuse {
  self.poster.image = nil;
  self.titleLabel.text = @"";
  self.subtitleLabel.text = @"";
}

#pragma mark UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.titleLabel.top = 0;
  [self.titleLabel setFrameToFitWithHeightLimit:20];
  if ([self.movie subtitle]) {
    [self.subtitleLabel setFrameToFitWithHeightLimit:40];
    self.subtitleLabel.top = self.titleLabel.bottom + 4;
    CGFloat verticalOffset = (self.height - self.subtitleLabel.bottom - 4) / 2;
    self.titleLabel.top += verticalOffset;
    self.subtitleLabel.top += verticalOffset;
  } else {
    self.titleLabel.top = (self.height - self.titleLabel.height) / 2;
  }
  self.selectedBackgroundView.frame = self.bounds;
}

#pragma mark Setters

- (void)setMovie:(SEAMovie *)movie {
  _movie = movie;

  [self.poster sd_setImageWithURL:movie.poster.url placeholderImage:[UIImage imageNamed:@"PosterPlaceholder"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    if (cacheType == SDImageCacheTypeNone) {
      self.poster.alpha = 0;
      [UIView animateWithDuration:0.3f animations:^{
        self.poster.alpha = 1;
      }];
    }
  }];

  self.titleLabel.text = movie.title;
  NSMutableAttributedString *subtitleText = [NSMutableAttributedString new];
  if ([movie subtitle]) {
    [subtitleText appendAttributedString:[[NSAttributedString alloc] initWithString:[movie subtitle] attributes:@{
                                            NSFontAttributeName : [UIFont systemFontOfSize:13]
                                          }]];
  }
  if ([[SEADataManager sharedInstance] citySupported] && [[SEADataManager sharedInstance] localShowtimesForMovie:movie].count > 0) {
    NSInteger showtimesCount = (NSInteger)[[SEADataManager sharedInstance] localShowtimesForMovie:movie].count;
    [subtitleText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@ %@ в %@", (subtitleText.length > 0 ? @"\n" : @""), @(showtimesCount), [NSString getNumEnding:showtimesCount endings:@[@"сеанс", @"сеанса", @"сеансов"]], [SEALocationManager sharedInstance].currentCity] attributes:@{
                                            NSFontAttributeName : [UIFont italicSystemFontOfSize:13]
                                          }]];
  }
  self.subtitleLabel.attributedText = subtitleText;
}

@end
