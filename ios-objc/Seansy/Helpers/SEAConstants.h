#pragma mark Type Definitions

typedef enum {
  SEAMoviesTypeNowPlaying,
  SEAMoviesTypeComingSoon
} SEAMoviesType;

typedef enum {
  SEAMoviesSortByName,
  SEAMoviesSortByPopularity,
  SEAMoviesSortByRating,
  SEAMoviesSortByShowtimesCount
} SEAMoviesSortBy;

typedef enum {
  SEATheatresSortByName,
  SEATheatresSortByDistance,
  SEATheatresSortByPrice,
  SEATheatresSortByShowtimesCount
} SEATheatresSortBy;

typedef enum {
  SEAShowtimesLayoutMovies,
  SEAShowtimesLayoutTheatres,
  SEAShowtimesLayoutTime
} SEAShowtimesLayout;

typedef void (^SEADismissHandler)(void);

#pragma mark Database Queries

extern NSString *const kNowPlayingMoviesQuery;
extern NSString *const kComingSoonMoviesQuery;
extern NSString *const kAllTheatresQuery;
extern NSString *const kAllNewsQuery;
extern NSString *const kAllShowtimesQuery;

#pragma mark Database Keys

extern NSString *const kIdKey;
extern NSString *const kBackdropKey;
extern NSString *const kBackdropUrlKey;
extern NSString *const kBackdropTextColorKey;
extern NSString *const kBackdropBackgroundColorKey;
extern NSString *const kBackdropColorsExtractedKey;

#pragma mark Sorting & Filtering Keys

extern NSString *const kMoviesSortByKey;
extern NSString *const kTheatresSortByKey;
extern NSString *const kMoviesRatingFilterKey;
extern NSString *const kMoviesRuntimeFilterKey;
extern NSString *const kMoviesChildrenFilterKey;
extern NSString *const kMoviesGenresFilterKey;

#pragma mark Settings Keys

extern NSString *const kShowPercentRatingsKey;
extern NSString *const kSaveFiltersKey;
extern NSString *const kParallaxKey;
extern NSString *const kCityNameKey;

#pragma mark Other Keys

extern NSString *const kSeenWalkthroughKey;
extern NSString *const kNowPlayingMoviesKey;
extern NSString *const kComingSoonMoviesKey;
extern NSString *const kTheatresKey;
extern NSString *const kShowtimesKey;
extern NSString *const kNewsKey;
extern NSString *const kOfflineDataExpirationDateKey;
extern NSString *const kStarredTheatresIdsKey;

#pragma mark Colors

extern NSString *const kAmberColor;
extern NSString *const kLightAmberColor;
extern NSString *const kGreenColor;
extern NSString *const kRedColor;
extern NSString *const kOnyxColor;
extern NSString *const kLightOnyxColor;
extern NSString *const kDarkOnyxColor;
extern NSString *const kDarkGreyColor;
extern NSString *const kLightGreyColor;

#pragma mark Notifications

extern NSString *const kDataLoadedNotification;
extern NSString *const kNowPlayingMoviesLoadedNotification;
extern NSString *const kComingSoonMoviesLoadedNotification;
extern NSString *const kTheatresLoadedNotification;
extern NSString *const kNewsLoadedNotification;
extern NSString *const kLoadingErrorNotification;
extern NSString *const kLocationLoadedNotification;

#pragma mark Fonts

extern CGFloat const kDisabledAlpha;
extern CGFloat const kSecondaryTextAlpha;

#pragma mark Location Selector

extern CGFloat const kLocationSelectorBounceOffset;
extern CGFloat const kLocationSelectorVelocityThreshold;
extern CGFloat const kLocationSelectorClosingVelocity;
extern CGFloat const kLocationSelectorPickerItemHeight;

#pragma mark Movies Carousel

extern NSString *const kCarouselTitleKey;
extern NSString *const kCarouselOffsetKey;
extern CGFloat const kCarouselRatingOffset;
extern CGFloat const kCarouselNameOffset;

#pragma mark Backdrop

extern CGFloat const kBackdropBlurRadius;
extern CGFloat const kBackdropBlurDarkeningRatio;
extern CGFloat const kBackdropBlurSaturationDeltaFactor;

#pragma mark Dimensions

extern CGFloat const kDateSectionHeaderViewHeight;
extern CGFloat const kMovieSectionHeaderViewHeight;
extern CGFloat const kTheatreSectionHeaderViewHeight;
extern CGFloat const kShowtimesCarouselHeight;
extern CGFloat const kShowtimesCarouselLabelHeight;
extern CGFloat const kShowtimesListCellHeight;
extern CGFloat const kModalViewCellHeight;
extern CGFloat const kShowtimesTableHeaderHeight;
extern CGFloat const kShowtimesPickerViewHeight;
extern CGFloat const kNewsEntryCellHeight;
extern CGFloat const kOnboardingBottomHeight;
extern CGFloat const kOnboardingTopHeight;
extern CGFloat const kReviewsCarouselCellWidth;
extern CGFloat const kMoviesTableViewCellHeight;

#pragma mark Modal View

extern CGFloat const kModalViewBlurRadius;
extern CGFloat const kModalViewBlurDarkeningRatio;
extern CGFloat const kModalViewBlurSaturationDeltaFactor;
extern NSTimeInterval const kModalViewAnimationDuration;

#pragma mark Miscellaneous

extern NSString *const kAppId;
extern NSString *const kYoutubeThumbnailUrlFormat;
extern NSString *const kAppGroup;
