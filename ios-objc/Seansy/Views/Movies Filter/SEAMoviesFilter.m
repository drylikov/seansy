#import "SEAMoviesFilter.h"

#import "AYMacros.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAMoviesFilterGenresSelectorCell.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"

UIEdgeInsets const kFilterViewPadding = {
  10, 10, 10, 10
};
CGFloat const kFilterViewLabelSpacing = 10;
CGFloat const kFilterViewSliderHeight = 45;
CGFloat const kFilterGenresSelectorCellHeight = 34;
UIEdgeInsets const kFilterGenresSelectorCellPadding = {
  0, 7, 0, 7
};

@interface SEAMoviesFilter () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) NSMutableArray *allGenres;
@property (nonatomic) UICollectionView *filterGenresSelector;
@property (nonatomic) UILabel *filterActiveRating;
@property (nonatomic) UILabel *filterActiveRuntime;
@property (nonatomic) UISwitch *filterChildrenSwitch;
@property (weak, nonatomic) SEADataManager *dataManager;

@end

@implementation SEAMoviesFilter

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.dataManager = [SEADataManager sharedInstance];
  if ([[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kSaveFiltersKey]) {
    self.ratingFilter = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kMoviesRatingFilterKey] ? : -1;
    if (self.ratingFilter > [self.dataManager maximumRatingForNowPlayingMovies]) {
      self.ratingFilter = -1;
    }
    self.runtimeFilter = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] integerForKey:kMoviesRuntimeFilterKey] ? : -1;
    if (self.runtimeFilter < [self.dataManager minimumRatingForNowPlayingMovies]) {
      self.runtimeFilter = -1;
    }
    self.genresFilter = [[[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] objectForKey:kMoviesGenresFilterKey] mutableCopy] ? : [NSMutableArray new];
    self.childrenFilter = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kMoviesChildrenFilterKey];
  } else {
    self.ratingFilter = -1;
    self.runtimeFilter = -1;
    self.genresFilter = [NSMutableArray new];
  }

  return self;
}

+ (SEAMoviesFilter *)sharedInstance {
  static SEAMoviesFilter *sharedInstance = nil;
  static dispatch_once_t oncePredicate;

  dispatch_once(&oncePredicate, ^{
    sharedInstance = [SEAMoviesFilter new];
  });
  return sharedInstance;
}

#pragma mark Rating slider

- (UIView *)ratingSlider {
  NSMutableArray *labels = [NSMutableArray new];
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFilterViewPadding.left, kFilterViewPadding.top, 0, 0)];

  titleLabel.text = NSLocalizedString(@"Мин. рейтинг:", nil);
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  [titleLabel sizeToFit];

  self.filterActiveRating = [[UILabel alloc] initWithFrame:CGRectMake(titleLabel.right + kFilterViewLabelSpacing, titleLabel.top, 0, 0)];
  self.filterActiveRating.textAlignment = NSTextAlignmentCenter;
  self.filterActiveRating.layer.borderWidth = 1;
  self.filterActiveRating.layer.borderColor = [UIColor colorWithHexString:kAmberColor].CGColor;
  self.filterActiveRating.layer.cornerRadius = 5;
  [labels addObject:self.filterActiveRating];

  UILabel *minRatingLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFilterViewPadding.left, titleLabel.bottom, 0, 0)];
  minRatingLabel.text = [NSString stringWithFormat:@"%@", @((NSInteger)[self.dataManager minimumRatingForNowPlayingMovies])];

  UILabel *maxRatingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, titleLabel.bottom, 0, 0)];
  maxRatingLabel.text = [NSString stringWithFormat:@"%@", @((NSInteger)([self.dataManager maximumRatingForNowPlayingMovies] + 0.5f))];

  for (UILabel *label in @[self.filterActiveRating, minRatingLabel, maxRatingLabel]) {
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  }

  [minRatingLabel sizeToFit];
  [maxRatingLabel sizeToFit];
  minRatingLabel.height = kFilterViewSliderHeight;
  maxRatingLabel.height = kFilterViewSliderHeight;
  maxRatingLabel.left = CGRectGetWidth([UIScreen mainScreen].bounds) - maxRatingLabel.width - kFilterViewLabelSpacing;

  UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(minRatingLabel.right + kFilterViewLabelSpacing, titleLabel.bottom, maxRatingLabel.left - minRatingLabel.right - kFilterViewLabelSpacing * 2, kFilterViewSliderHeight)];
  [slider addTarget:self action:@selector(updateRatingSlider:) forControlEvents:UIControlEventValueChanged];
  slider.backgroundColor = [UIColor clearColor];
  slider.tintColor = [UIColor colorWithHexString:kAmberColor];
  slider.minimumValue = (float)[self.dataManager minimumRatingForNowPlayingMovies];
  slider.maximumValue = (float)[self.dataManager maximumRatingForNowPlayingMovies];
  if (self.ratingFilter >= 0) {
    slider.value = self.ratingFilter;
  } else {
    slider.value = slider.minimumValue;
  }

  self.ratingFilter = (NSInteger)slider.value;
  slider.continuous = NO;

  UIView *sliderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), slider.bottom + kFilterViewPadding.bottom)];
  [sliderContainer addSubview:titleLabel];
  [sliderContainer addSubview:self.filterActiveRating];
  [sliderContainer addSubview:minRatingLabel];
  [sliderContainer addSubview:maxRatingLabel];
  [sliderContainer addSubview:slider];

  return sliderContainer;
}

- (void)updateRatingSlider:(UISlider *)slider {
  self.ratingFilter = (NSInteger)slider.value;
}

- (void)setRatingFilter:(NSInteger)ratingFilter {
  _ratingFilter = ratingFilter;
  if (ratingFilter != [self.dataManager minimumRatingForNowPlayingMovies]) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setInteger:self.ratingFilter forKey:kMoviesRatingFilterKey];
  } else {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] removeObjectForKey:kMoviesRatingFilterKey];
  }
  self.filterActiveRating.text = [NSString stringWithFormat:@"%@%%", @(ratingFilter)];
  [self.filterActiveRating sizeToFit];
  self.filterActiveRating.width += 10;
}

#pragma mark Runtime slider

- (UIView *)runtimeSlider {
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFilterViewPadding.left, kFilterViewPadding.top, 0, 0)];

  titleLabel.text = NSLocalizedString(@"Макс. длительность:", nil);
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  [titleLabel sizeToFit];

  self.filterActiveRuntime = [[UILabel alloc] initWithFrame:CGRectMake(titleLabel.right + kFilterViewLabelSpacing, titleLabel.top, 0, 0)];
  self.filterActiveRuntime.textAlignment = NSTextAlignmentCenter;
  self.filterActiveRuntime.layer.borderWidth = 1;
  self.filterActiveRuntime.layer.borderColor = [UIColor colorWithHexString:kAmberColor].CGColor;
  self.filterActiveRuntime.layer.cornerRadius = 5;

  UILabel *minRuntimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFilterViewPadding.left, titleLabel.bottom, 0, 0)];
  minRuntimeLabel.text = [NSString stringWithFormat:@"%@", @((NSInteger)([self.dataManager minimumRuntimeForNowPlayingMovies] / 60.f))];

  UILabel *maxRuntimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, titleLabel.bottom, 0, 0)];
  maxRuntimeLabel.text = [NSString stringWithFormat:@"%@", @((NSInteger)([self.dataManager maximumRuntimeForNowPlayingMovies] / 60.f + 0.5f))];

  for (UILabel *label in @[self.filterActiveRuntime, minRuntimeLabel, maxRuntimeLabel]) {
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  }

  [minRuntimeLabel sizeToFit];
  [maxRuntimeLabel sizeToFit];
  minRuntimeLabel.height = kFilterViewSliderHeight;
  maxRuntimeLabel.height = kFilterViewSliderHeight;
  maxRuntimeLabel.left = CGRectGetWidth([UIScreen mainScreen].bounds) - maxRuntimeLabel.width - kFilterViewLabelSpacing;

  UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(minRuntimeLabel.right + kFilterViewLabelSpacing, titleLabel.bottom, maxRuntimeLabel.left - minRuntimeLabel.right - kFilterViewLabelSpacing * 2, kFilterViewSliderHeight)];
  [slider addTarget:self action:@selector(updateRuntimeSlider:) forControlEvents:UIControlEventValueChanged];
  slider.backgroundColor = [UIColor clearColor];
  slider.tintColor = [UIColor colorWithHexString:kAmberColor];
  slider.minimumValue = (float)[self.dataManager minimumRuntimeForNowPlayingMovies];
  slider.maximumValue = (float)[self.dataManager maximumRuntimeForNowPlayingMovies];
  if (self.runtimeFilter >= 0) {
    slider.value = self.runtimeFilter;
  } else {
    slider.value = slider.maximumValue;
  }

  self.runtimeFilter = (NSInteger)slider.value;
  slider.continuous = NO;

  UIView *sliderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), slider.bottom + kFilterViewPadding.bottom)];
  [sliderContainer addSubview:titleLabel];
  [sliderContainer addSubview:self.filterActiveRuntime];
  [sliderContainer addSubview:minRuntimeLabel];
  [sliderContainer addSubview:maxRuntimeLabel];
  [sliderContainer addSubview:slider];

  return sliderContainer;
}

- (void)updateRuntimeSlider:(UISlider *)slider {
  self.runtimeFilter = (NSInteger)slider.value;
}

- (void)setRuntimeFilter:(NSInteger)runtimeFilter {
  _runtimeFilter = runtimeFilter;
  if (runtimeFilter != [self.dataManager maximumRuntimeForNowPlayingMovies]) {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setInteger:self.runtimeFilter forKey:kMoviesRuntimeFilterKey];
  } else {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] removeObjectForKey:kMoviesRuntimeFilterKey];
  }
  self.filterActiveRuntime.text = [NSString stringWithFormat:@"%@ мин.", @((NSInteger)(runtimeFilter / 60.f))];
  [self.filterActiveRuntime sizeToFit];
  self.filterActiveRuntime.width += 10;
}

#pragma mark Children switch

- (UIView *)childrenSwitch {
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFilterViewPadding.left, 0, 0, 0)];

  titleLabel.text = NSLocalizedString(@"Для детей:", nil);
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  [titleLabel sizeToFit];

  self.filterChildrenSwitch = [UISwitch new];
  self.filterChildrenSwitch.left = titleLabel.right + kFilterViewLabelSpacing;
  [self.filterChildrenSwitch addTarget:self action:@selector(updateChildrenSwitch:) forControlEvents:UIControlEventValueChanged];
  self.filterChildrenSwitch.tintColor = [UIColor colorWithHexString:kAmberColor];
  self.filterChildrenSwitch.onTintColor = self.filterChildrenSwitch.tintColor;
  self.filterChildrenSwitch.on = self.childrenFilter;
  titleLabel.centerY = self.filterChildrenSwitch.centerY;

  UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, kFilterViewPadding.top, CGRectGetWidth([UIScreen mainScreen].bounds), self.filterChildrenSwitch.height + kFilterViewPadding.top + kFilterViewPadding.bottom)];
  [switchContainer addSubview:titleLabel];
  [switchContainer addSubview:self.filterChildrenSwitch];

  return switchContainer;
}

- (void)updateChildrenSwitch:(UISwitch *)sender {
  self.childrenFilter = sender.isOn;
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setBool:self.childrenFilter forKey:kMoviesChildrenFilterKey];
}

#pragma mark Genres selector

- (UIView *)genresSelector {
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFilterViewPadding.left, kFilterViewPadding.top, 0, 0)];

  titleLabel.text = NSLocalizedString(@"Жанры", nil);
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  [titleLabel sizeToFit];

  UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
  [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];

  self.filterGenresSelector = [[UICollectionView alloc] initWithFrame:CGRectMake(0, titleLabel.bottom + kFilterViewLabelSpacing, CGRectGetWidth([UIScreen mainScreen].bounds), kFilterGenresSelectorCellHeight) collectionViewLayout:flowLayout];
  self.filterGenresSelector.delegate = self;
  self.filterGenresSelector.dataSource = self;
  [self.filterGenresSelector registerClass:[SEAMoviesFilterGenresSelectorCell class] forCellWithReuseIdentifier:NSStringFromClass([SEAMoviesFilterGenresSelectorCell class])];
  self.filterGenresSelector.backgroundColor = [UIColor clearColor];
  self.filterGenresSelector.showsHorizontalScrollIndicator = NO;

  NSMutableArray *sortedGenres = [[self.dataManager allGenresForNowPlayingMovies] mutableCopy];
  [sortedGenres removeObjectsInArray:self.genresFilter];
  self.allGenres = [self.genresFilter mutableCopy];
  [self.allGenres addObjectsFromArray:sortedGenres];

  UIView *selectorContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), self.filterGenresSelector.bottom + kFilterViewPadding.bottom)];
  [selectorContainer addSubview:titleLabel];
  [selectorContainer addSubview:self.filterGenresSelector];

  return selectorContainer;
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return (NSInteger)self.allGenres.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
  return UIEdgeInsetsMake(0, kFilterViewPadding.left, 0, kFilterViewPadding.right);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  return 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  NSString *genre = self.allGenres[(NSUInteger)indexPath.row];
  CGSize labelSize = [genre boundingRectWithSize:CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - kFilterViewPadding.left - kFilterViewPadding.right, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : [UIFont regularFontWithSize:[UIFont mediumTextFontSize]] } context:nil].size;

  return CGSizeMake(kFilterGenresSelectorCellPadding.left + labelSize.width + kFilterGenresSelectorCellPadding.right, kFilterGenresSelectorCellPadding.top + kFilterGenresSelectorCellHeight + kFilterGenresSelectorCellPadding.bottom);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  SEAMoviesFilterGenresSelectorCell *cell = (SEAMoviesFilterGenresSelectorCell *)[collectionView  dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SEAMoviesFilterGenresSelectorCell class]) forIndexPath:indexPath];
  NSString *genre = self.allGenres[(NSUInteger)indexPath.row];

  cell.label.text = genre;
  if ([self.genresFilter indexOfObject:genre] != NSNotFound) {
    cell.active = YES;
  }

  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  NSString *genre = self.allGenres[(NSUInteger)indexPath.row];
  SEAMoviesFilterGenresSelectorCell *cell = (SEAMoviesFilterGenresSelectorCell *)[self.filterGenresSelector cellForItemAtIndexPath:indexPath];

  if ([self.genresFilter indexOfObject:genre] == NSNotFound) {
    [self.genresFilter addObject:genre];
    cell.active = YES;
  } else {
    [self.genresFilter removeObject:genre];
    cell.active = NO;
  }

  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setObject:self.genresFilter forKey:kMoviesGenresFilterKey];
}

@end
