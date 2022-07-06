#import "SEAShowtimesCarouselWithLabel.h"

#import "SEAConstants.h"
#import "SEAShowtime.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"

@implementation SEAShowtimesCarouselWithLabel

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.label = [[UILabel alloc] initWithFrame:CGRectMake(kShowtimesCellCollectionViewPadding.left, kShowtimesCellCollectionViewPadding.top, CGRectGetWidth([UIScreen mainScreen].bounds) - kShowtimesCellCollectionViewPadding.left - kShowtimesCellCollectionViewPadding.right, kShowtimesCarouselLabelHeight - kShowtimesCellCollectionViewPadding.top)];
  self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.label.textColor = [UIColor whiteColor];
  self.collectionView.top += kShowtimesCarouselLabelHeight;
  [self.contentView addSubview:self.label];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.label.alpha = 1;
  self.label.text = nil;
}

#pragma mark Setters

- (void)setTheatre:(SEATheatre *)theatre {
  [super setTheatre:theatre];
  if (self.currentLayout == SEAShowtimesLayoutMovies) {
    if ([theatre distance]) {
      self.label.attributedText = [self theatreNameWithDistance];
    } else if (self.theatre.isFavorite) {
      self.label.text = [NSString stringWithFormat:@"☆ %@", self.theatre.name];
    } else {
      self.label.text = self.theatre.name;
    }
  }
}

- (void)setMovie:(SEAMovie *)movie {
  [super setMovie:movie];
  if (self.currentLayout == SEAShowtimesLayoutTheatres || self.currentLayout == SEAShowtimesLayoutTime) {
    if (movie.age >= 0) {
      self.label.attributedText = [self movieTitleWithAge];
    } else {
      self.label.text = self.movie.title;
    }
  }
}

- (void)setShowtimes:(NSMutableArray *)showtimes {
  [super setShowtimes:showtimes];
  if (self.currentLayout == SEAShowtimesLayoutTime) {
    if ([self.showtimes[0] hasPassed]) {
      self.label.alpha = kDisabledAlpha;
    } else {
      self.label.alpha = 1;
    }
  }
}

#pragma mark Helpers

- (NSAttributedString *)movieTitleWithAge {
  NSMutableString *titleString = [[NSMutableString alloc] initWithString:self.movie.title];
  NSString *ageString = [NSString stringWithFormat:@" (%@+)", @(self.movie.age)];
  CGFloat ageWidth = [self stringWidth:ageString font:self.label.font];
  CGFloat titleWidth = [self stringWidth:titleString font:self.label.font];
  CGFloat ellipsisWidth = [self stringWidth:@"..." font:self.label.font];
  CGFloat widthLimit = CGRectGetWidth([UIScreen mainScreen].bounds) - 24;

  if (titleWidth + ageWidth > widthLimit) {
    widthLimit -= ellipsisWidth;
    NSRange range = {
      titleString.length - 1, 1
    };
    while ([self stringWidth:[NSString stringWithFormat:@"%@%@", titleString, ageString] font:self.label.font] > widthLimit) {
      [titleString deleteCharactersInRange:range];
      range.location--;
    }
    [titleString replaceCharactersInRange:range withString:@"..."];
  }

  NSMutableAttributedString *movieTitleWithAge = [[NSMutableAttributedString alloc] initWithString:titleString attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
  [movieTitleWithAge appendAttributedString:[[NSAttributedString alloc] initWithString:ageString attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:kSecondaryTextAlpha] }]];
  return movieTitleWithAge;
}

- (NSAttributedString *)theatreNameWithDistance {
  NSMutableString *nameString;

  if (self.theatre.isFavorite) {
    nameString = [[NSString stringWithFormat:@"☆ %@", self.theatre.name] mutableCopy];
  } else {
    nameString = [self.theatre.name mutableCopy];
  }

  NSString *distanceString = [NSString stringWithFormat:@" (%@)", [self.theatre distance]];
  CGFloat distanceWidth = [self stringWidth:distanceString font:self.label.font];
  CGFloat nameWidth = [self stringWidth:nameString font:self.label.font];
  CGFloat ellipsisWidth = [self stringWidth:@"..." font:self.label.font];
  CGFloat widthLimit = CGRectGetWidth([UIScreen mainScreen].bounds) - 24;
  if (nameWidth + distanceWidth > widthLimit) {
    widthLimit -= ellipsisWidth;
    NSRange range = {
      nameString.length - 1, 1
    };
    while ([self stringWidth:[NSString stringWithFormat:@"%@%@", nameString, distanceString] font:self.label.font] > widthLimit) {
      [nameString deleteCharactersInRange:range];
      range.location--;
    }
    [nameString replaceCharactersInRange:range withString:@"..."];
  }

  NSMutableAttributedString *theatreNameWithDistance = [[NSMutableAttributedString alloc] initWithString:nameString attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
  [theatreNameWithDistance appendAttributedString:[[NSAttributedString alloc] initWithString:distanceString attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:kSecondaryTextAlpha] }]];
  return theatreNameWithDistance;
}

- (CGFloat)stringWidth:(NSString *)string font:(UIFont *)font {
  return [string boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : font } context:nil].size.width;
}

@end
