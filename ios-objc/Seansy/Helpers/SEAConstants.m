#import "SEAConstants.h"

#pragma mark Database Queries

NSString *const kNowPlayingMoviesQuery = @"movies?filter[where][date]=null";
NSString *const kComingSoonMoviesQuery = @"movies?filter[where][date][neq]";
NSString *const kAllTheatresQuery = @"theatres";
NSString *const kAllNewsQuery = @"news";
NSString *const kAllShowtimesQuery = @"showtimes?filter={\"where\":{}}";

#pragma mark Database Keys

NSString *const kIdKey = @"id";
NSString *const kBackdropKey = @"backdrop";
NSString *const kBackdropUrlKey = @"backdropUrl";
NSString *const kBackdropTextColorKey = @"textColor";
NSString *const kBackdropBackgroundColorKey = @"backgroundColor";
NSString *const kBackdropColorsExtractedKey = @"colorsExtracted";

#pragma mark Sorting & Filtering Keys

NSString *const kMoviesSortByKey = @"moviesSortBy";
NSString *const kTheatresSortByKey = @"theatresSortBy";
NSString *const kMoviesRatingFilterKey = @"ratingFilter";
NSString *const kMoviesRuntimeFilterKey = @"runtimeFilter";
NSString *const kMoviesChildrenFilterKey = @"childrenFilter";
NSString *const kMoviesGenresFilterKey = @"genresFilter";

#pragma mark Settings Keys

NSString *const kShowPercentRatingsKey = @"showPercentRatings";
NSString *const kSaveFiltersKey = @"saveFilters";
NSString *const kParallaxKey = @"parallax";
NSString *const kCityNameKey = @"cityName";

#pragma mark Other Keys

NSString *const kSeenWalkthroughKey = @"seenWalkthrough";
NSString *const kNowPlayingMoviesKey = @"nowPlayingMovies";
NSString *const kComingSoonMoviesKey = @"comingSoonMovies";
NSString *const kTheatresKey = @"theatres";
NSString *const kShowtimesKey = @"showtimes";
NSString *const kNewsKey = @"news";
NSString *const kOfflineDataExpirationDateKey = @"offlineDataExpirationDate";
NSString *const kStarredTheatresIdsKey = @"starredTheatreIds";

#pragma mark Colors

NSString *const kAmberColor = @"#FFD54F";
NSString *const kLightAmberColor = @"FFECB3";
NSString *const kGreenColor = @"#50AE55";
NSString *const kRedColor = @"#F1453D";
NSString *const kOnyxColor = @"#141414";
NSString *const kLightOnyxColor = @"#202020";
NSString *const kDarkOnyxColor = @"#121212";
NSString *const kDarkGreyColor = @"4D4D4D";
NSString *const kLightGreyColor = @"CCCCCC";

#pragma mark Notifications

NSString *const kDataLoadedNotification = @"dataLoaded";
NSString *const kNowPlayingMoviesLoadedNotification = @"nowPlayingMoviesLoaded";
NSString *const kComingSoonMoviesLoadedNotification = @"comingSoonMoviesLoaded";
NSString *const kTheatresLoadedNotification = @"theatresLoaded";
NSString *const kNewsLoadedNotification = @"newsLoaded";
NSString *const kLoadingErrorNotification = @"loadingError";
NSString *const kLocationLoadedNotification = @"locationLoaded";

#pragma mark Fonts

CGFloat const kDisabledAlpha = 0.3f;
CGFloat const kSecondaryTextAlpha = 0.7f;

#pragma mark Location Selector

CGFloat const kLocationSelectorBounceOffset = 10;
CGFloat const kLocationSelectorVelocityThreshold = 1000;
CGFloat const kLocationSelectorClosingVelocity = 1200;
CGFloat const kLocationSelectorPickerItemHeight = 30;

#pragma mark Movies Carousel

NSString *const kCarouselTitleKey = @"carouselLabel";
NSString *const kCarouselOffsetKey = @"carouselOffset";
CGFloat const kCarouselRatingOffset = 26;
CGFloat const kCarouselNameOffset = 50;

#pragma mark Backdrop

CGFloat const kBackdropBlurRadius = 14;
CGFloat const kBackdropBlurDarkeningRatio = 0.5f;
CGFloat const kBackdropBlurSaturationDeltaFactor = 1.4f;

#pragma mark Dimensions

CGFloat const kDateSectionHeaderViewHeight = 40;
CGFloat const kMovieSectionHeaderViewHeight = 100;
CGFloat const kTheatreSectionHeaderViewHeight = 80;
CGFloat const kShowtimesCarouselHeight = 64;
CGFloat const kShowtimesCarouselLabelHeight = 32;
CGFloat const kShowtimesListCellHeight = 140;
CGFloat const kModalViewCellHeight = 50;
CGFloat const kShowtimesTableHeaderHeight = 56;
CGFloat const kShowtimesPickerViewHeight = 75;
CGFloat const kNewsEntryCellHeight = 150;
CGFloat const kOnboardingBottomHeight = 44;
CGFloat const kOnboardingTopHeight = 44;
CGFloat const kReviewsCarouselCellWidth = 250;
CGFloat const kMoviesTableViewCellHeight = 70;

#pragma mark Modal View

CGFloat const kModalViewBlurRadius = 8;
CGFloat const kModalViewBlurDarkeningRatio = 0.4f;
CGFloat const kModalViewBlurSaturationDeltaFactor = 1.4f;
NSTimeInterval const kModalViewAnimationDuration = 0.4f;

#pragma mark Miscellaneous

NSString *const kAppId = @"980255991";
NSString *const kYoutubeThumbnailUrlFormat = @"http://img.youtube.com/vi/%@/maxresdefault.jpg";
NSString *const kAppGroup = @"group.kz.yenbekbay.Seansy";
