#import "SEANavigationBarTitleView.h"

#import "SEAArrowIcon.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"

CGSize const kNavigationBarTitleViewArrowIconSize = {
  14, 1
};
CGFloat const kNavigationBarTitleViewArrowIconLeftMargin = 10;

@interface SEANavigationBarTitleView ()

@property (nonatomic) UILabel *cityLabel;
@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) SEAArrowIcon *arrowIcon;

@end

@implementation SEANavigationBarTitleView

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.cityLabel = [UILabel new];
  self.cityLabel.font = [UIFont regularFontWithSize:[UIFont navigationBarFontSize]];
  self.cityLabel.textColor = [UIColor whiteColor];
  [self addSubview:self.cityLabel];

  self.dateLabel = [UILabel new];
  self.dateLabel.font = [UIFont regularFontWithSize:13];
  self.dateLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75f];
  [self addSubview:self.dateLabel];

  self.arrowIcon = [[SEAArrowIcon alloc] initWithFrame:CGRectMake(0, 0, kNavigationBarTitleViewArrowIconSize.width, kNavigationBarTitleViewArrowIconSize.height) orientation:SEAArrowIconOrientationHorizontal];
  [self addSubview:self.arrowIcon];
  [self pointArrowDown];
  [self updateView];

  return self;
}

#pragma mark Setters

- (void)setCity:(NSString *)city {
  _city = city;
  self.cityLabel.text = city;
  [self updateView];
}

- (void)setDateIndex:(SEAShowtimesDate)dateIndex {
  _dateIndex = dateIndex;
  switch (dateIndex) {
    case SEAShowtimesDateToday:
      self.dateLabel.text = @"";
      break;
    case SEAShowtimesDateTomorrow:
      self.dateLabel.text = NSLocalizedString(@"завтра", nil);
      break;
    default:
      break;
  }
  [self updateView];
}

#pragma mark Public

- (void)pointArrowUp {
  [self.arrowIcon pointUpAnimated:YES];
}

- (void)pointArrowDown {
  [self.arrowIcon pointDownAnimated:YES];
}

#pragma mark UIView

- (void)updateView {
  [self.cityLabel sizeToFit];
  [self.dateLabel sizeToFit];
  self.dateLabel.centerX = self.cityLabel.centerX;
  self.dateLabel.top = self.cityLabel.bottom;
  self.arrowIcon.left = MAX(self.cityLabel.right, self.dateLabel.right) + kNavigationBarTitleViewArrowIconLeftMargin;
  self.arrowIcon.centerY = self.dateLabel.bottom / 2;
  self.width = self.arrowIcon.right;
  self.height = self.dateLabel.bottom;
}

@end
