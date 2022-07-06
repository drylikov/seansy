#import "SEAShowtimeInfoView.h"

#import "AYMacros.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAMovie.h"
#import "SEAStarRatingView.h"
#import "SEATheatre.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"

CGSize const kShowtimeInfoViewMovieRatingSize = {
  128, 24
};
CGFloat const kShowtimeInfoViewLabelsVerticalSpacing = 5;
CGFloat const kShowtimeInfoViewLabelsHorizontalSpacing = 10;

@interface SEAShowtimeInfoView ()

@property (nonatomic) SEAStarRatingView *movieRating;
@property (nonatomic) UILabel *bigTimeLabel;
@property (nonatomic) UILabel *formatLabel;
@property (nonatomic) UILabel *movieAge;
@property (nonatomic) UILabel *movieGenres;
@property (nonatomic) UILabel *movieRuntime;
@property (nonatomic) UILabel *movieTitleLabel;
@property (nonatomic) UILabel *smallTimeLabel;
@property (nonatomic) UILabel *theatreNameLabel;
@property (weak, nonatomic) SEAMovie *movie;
@property (weak, nonatomic) SEAShowtime *showtime;
@property (weak, nonatomic) SEATheatre *theatre;

@end

@implementation SEAShowtimeInfoView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame showtime:(SEAShowtime *)showtime {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.showtime = showtime;
  self.theatre = [[SEADataManager sharedInstance] theatreForId:showtime.theatreId];
  self.movie = [[SEADataManager sharedInstance] movieForId:showtime.movieId];

  self.movieTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.width, 0)];
  self.movieTitleLabel.text = self.movie.title;
  self.movieTitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9f];
  self.movieTitleLabel.font = [UIFont lightFontWithSize:[UIFont showtimeTitleFontSize]];
  self.movieTitleLabel.textAlignment = NSTextAlignmentCenter;
  [self.movieTitleLabel adjustFontSizeWithMaxLines:2 fontFloor:IS_IPHONE_6P ? 32 : 26];
  CGFloat verticalOffset = self.movieTitleLabel.bottom;
  [self addSubview:self.movieTitleLabel];

  if (self.movie.averageRating > 0) {
    self.movieRating = [[SEAStarRatingView alloc] initWithFrame:CGRectMake((self.width - kShowtimeInfoViewMovieRatingSize.width) / 2, self.movieTitleLabel.bottom, kShowtimeInfoViewMovieRatingSize.width, kShowtimeInfoViewMovieRatingSize.height)];
    self.movieRating.minimumValue = 0;
    self.movieRating.maximumValue = 5;
    self.movieRating.tintColor = [UIColor colorWithHexString:kAmberColor];
    self.movieRating.value = self.movie.averageRating / 100 * 5;
    verticalOffset = self.movieRating.bottom + kShowtimeInfoViewLabelsVerticalSpacing;
    [self addSubview:self.movieRating];
  }

  if (self.movie.genre) {
    self.movieGenres = [[UILabel alloc] initWithFrame:CGRectMake(0, verticalOffset, self.width, 0)];
    self.movieGenres.text = [self.movie genreString];
    self.movieGenres.textColor = [UIColor whiteColor];
    self.movieGenres.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    self.movieGenres.textAlignment = NSTextAlignmentCenter;
    self.movieGenres.numberOfLines = 0;
    [self.movieGenres setFrameToFitWithHeightLimit:60];
    verticalOffset = self.movieGenres.bottom + kShowtimeInfoViewLabelsVerticalSpacing;
    [self addSubview:self.movieGenres];
  }

  if (self.movie.age >= 0 || self.movie.runtime > 0) {
    if (self.movie.age >= 0) {
      self.movieAge = [[UILabel alloc] initWithFrame:CGRectMake(0, verticalOffset, 0, 0)];
      self.movieAge.text = [NSString stringWithFormat:@"%@+", @(self.movie.age)];
      self.movieAge.textColor = [UIColor whiteColor];
      self.movieAge.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
      self.movieAge.textAlignment = NSTextAlignmentCenter;
      self.movieAge.layer.borderWidth = 1;
      self.movieAge.layer.borderColor = [UIColor whiteColor].CGColor;
      self.movieAge.layer.shadowOffset = CGSizeMake(1, 1);
      self.movieAge.layer.shadowRadius = 0;
      self.movieAge.layer.shadowColor = [UIColor blackColor].CGColor;
      self.movieAge.layer.shadowOpacity = 0.5f;
      [self.movieAge sizeToFit];
      self.movieAge.width += 8;
      self.movieAge.height += 4;
      [self addSubview:self.movieAge];
    }
    if (self.movie.runtime > 0) {
      self.movieRuntime = [[UILabel alloc] initWithFrame:CGRectMake(0, verticalOffset, 0, 0)];
      self.movieRuntime.text = [self.movie runtimeString];
      self.movieRuntime.textColor = [UIColor whiteColor];
      self.movieRuntime.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
      [self.movieRuntime sizeToFit];
      if (!self.movieAge) {
        self.movieRuntime.centerX = self.centerX;
      } else {
        self.movieRuntime.left = self.movieAge.right + kShowtimeInfoViewLabelsHorizontalSpacing;
        CGFloat horizontalOffset = (self.width - self.movieRuntime.right) / 2;
        self.movieAge.left += horizontalOffset;
        self.movieRuntime.left += horizontalOffset;
        self.movieRuntime.centerY = self.movieAge.centerY;
      }
      verticalOffset = self.movieRuntime.bottom + kShowtimeInfoViewLabelsVerticalSpacing;
      [self addSubview:self.movieRuntime];
    } else {
      self.movieAge.centerX = self.centerX;
      verticalOffset = self.movieAge.bottom + kShowtimeInfoViewLabelsVerticalSpacing;
    }
  }

  self.smallTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, verticalOffset, self.width, 0)];
  self.smallTimeLabel.text = [self.showtime timeString];
  self.smallTimeLabel.font = [UIFont timeFontWithSize:200];
  self.smallTimeLabel.textColor = [UIColor colorWithHexString:kAmberColor];
  self.smallTimeLabel.textAlignment = NSTextAlignmentCenter;
  [self.smallTimeLabel adjustFontSizeWithMaxLines:1 fontFloor:[UIFont largeTextFontSize]];
  verticalOffset = self.smallTimeLabel.bottom + kShowtimeInfoViewLabelsVerticalSpacing;
  [self addSubview:self.smallTimeLabel];

  if (self.showtime.format) {
    self.formatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.smallTimeLabel.bottom - 20, self.width, 0)];
    self.formatLabel.text = self.showtime.formatString;
    self.formatLabel.font = [UIFont regularFontWithSize:[UIFont showtimeFormatFontSize]];
    self.formatLabel.textColor = [UIColor colorWithHexString:kAmberColor];
    self.formatLabel.textAlignment = NSTextAlignmentCenter;
    [self.formatLabel adjustFontSizeWithMaxLines:1 fontFloor:[UIFont mediumTextFontSize]];
    verticalOffset = self.formatLabel.bottom + 20 + kShowtimeInfoViewLabelsVerticalSpacing;
    [self addSubview:self.formatLabel];
  }

  self.theatreNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, verticalOffset, self.width, 0)];
  self.theatreNameLabel.text = self.theatre.name;
  self.theatreNameLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9f];
  self.theatreNameLabel.font = [UIFont lightFontWithSize:[UIFont showtimeTitleFontSize]];
  self.theatreNameLabel.textAlignment = NSTextAlignmentCenter;
  [self.theatreNameLabel adjustFontSizeWithMaxLines:2 fontFloor:IS_IPHONE_6P ? 32 : 26];
  [self addSubview:self.theatreNameLabel];

  self.bigTimeLabel = [UILabel new];
  self.bigTimeLabel.text = [self.showtime timeString];
  self.bigTimeLabel.font = [UIFont timeFontWithSize:400];
  self.bigTimeLabel.textColor = [UIColor colorWithHexString:kAmberColor];
  self.bigTimeLabel.alpha = 0.1f;
  [self.bigTimeLabel sizeToFit];
  self.bigTimeLabel.center = self.smallTimeLabel.center;
  [self insertSubview:self.bigTimeLabel belowSubview:self.smallTimeLabel];

  self.height = self.theatreNameLabel.bottom;

  return self;
}

@end
