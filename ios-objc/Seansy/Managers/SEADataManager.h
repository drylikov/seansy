#import "SEAMovie.h"
#import "SEANewsEntry.h"
#import "SEAShowtime.h"
#import "SEATheatre.h"
#import <CoreLocation/CoreLocation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

typedef enum {
  SEAShowtimesDateToday,
  SEAShowtimesDateTomorrow
} SEAShowtimesDate;

/**
 *  Completes requests to the showtimes API and provides helpers to deal with the data from the API.
 *  Requests can return data regarding movies, showtimes, and theatres in given cities.
 */
@interface SEADataManager : NSObject

#pragma mark Methods

/**
 *  Access the shared data manager object.
 *
 *  @return The shared data manager object.
 */
+ (SEADataManager *)sharedInstance;
/**
 *  Connects to the API and retrieves the information for now playing and coming soon movies, active theatres,
 *  and showtimes for these theatres.
 *
 *  @param fromCache Indicates whether or not the data should be taken from cache if possible.
 */
- (RACSignal *)loadDataFromCache:(BOOL)fromCache;
/**
 *  Clears currently loaded news and reloads them.
 */
- (RACSignal *)reloadNews;
/**
 *  Removes all the cached data that may have been retrieved previously.
 */
- (void)reset;
/**
 *  Clears all the data saved in the device's memory.
 */
- (void)clearCache;
/**
 *  Saves ids for the user's favorite theatres.
 */
- (void)saveStarredTheatresIds;
/**
 * Saves now playing movies to Spotlight index.
 */
- (RACSignal *)setUpSpotlightSearch;
/**
 *  Retrieves the movie instance for the given movie id.
 *
 *  @param id Movie id to look for.
 *
 *  @return Movie instance from the allocated movies array.
 */
- (SEAMovie *)movieForId:(NSInteger)id;
/**
 *  Retrieves the theatre instance with the given theatre id.
 *
 *  @param id Theatre id to look for.
 *
 *  @return Theatre instance from the allocated theatres array.
 */
- (SEATheatre *)theatreForId:(NSInteger)id;
/**
 *  Returns instances of all movies playing in all theatres of the given city.
 *
 *  @param city Name of the city to get movies for.
 *
 *  @return Array of movie instances.
 */
- (NSArray *)moviesForCity:(NSString *)city;
/**
 *  Returns instances of all movies playing in the given theatre.
 *
 *  @param theatre Theatre to get movies for.
 *
 *  @return Array of movie instances.
 */
- (NSArray *)moviesForTheatre:(SEATheatre *)theatre;
/**
 *  Returns instances of all theatres that have the given movie currently playing.
 *
 *  @param movie Movie that should be playing in the theatres.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)theatresForMovie:(SEAMovie *)movie;
/**
 *  Returns instances of all theatres that have given movies currently playing.
 *
 *  @param movies Movies that should be playing in the theatres.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)theatresForMovies:(NSArray *)movies;
/**
 *  Returns instances of all theatres given showtime instances belong to.
 *
 *  @param showtimes Showtimes that should belong to the theatres.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)theatresForShowtimes:(NSArray *)showtimes;
/**
 *  Returns instances of all theatres in the given city.
 *
 *  @param city Name of the city to get movies for.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)theatresForCity:(NSString *)city;
/**
 *  Returns instances of theatres in the selected city that have the given movie currently playing.
 *
 *  @param movie Movie that should be playing in the theatres.
 *  @param city Name of the city to get movies for.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)theatresForMovie:(SEAMovie *)movie city:(NSString *)city;
/**
 *  Returns instances of all movies given showtime instances belong to.
 *
 *  @param showtimes Showtimes that should belong to the movies.
 *
 *  @return Array of movie instances.
 */
- (NSArray *)moviesForShowtimes:(NSArray *)showtimes;
/**
 *  Returns instances of all showtimes in all theatres.
 *
 *  @return Array of showtime instances.
 */
- (NSArray *)allShowtimes;
/**
 *  Returns instanes of all showtimes for given movies.
 *
 *  @param movies Movies to get showtimes for.
 *
 *  @return Array of showtime instances.
 */
- (NSArray *)showtimesForMovies:(NSArray *)movies;
/**
 *  Returns dates of given showtimes.
 *
 *  @param showtimes Showtimes to get dates for.
 *
 *  @return Array of showtimes dates.
 */
- (NSArray *)datesForShowtimes:(NSArray *)showtimes;
/**
 *  Returns names of all cities that contain supported theatres.
 *
 *  @return Array of city names.
 */
- (NSArray *)allCities;
/**
 *  Returns all genres of now playing movies.
 *
 *  @return Array of now playing movies' genres.
 */
- (NSArray *)allGenresForNowPlayingMovies;
/**
 *  Returns all release dates for upcoming movies.
 *
 *  @return Array of upcoming movies' dates as NSDates.
 */
- (NSArray *)allDatesForComingSoonMovies;
/**
 *  Checks if the city corresponding to the user's current location is supported.
 *
 *  @return BOOL whether or not the city is supported.
 */
- (BOOL)citySupported;
/**
 *  Returns instances of movies currently playing in the selected city.
 *
 *  @return Array of movie instances.
 */
- (NSArray *)localNowPlayingMovies;
/**
 *  Returns instances of theatres in the selected city that have the given movie currently playing.
 *
 *  @param movie Movie that should be playing in the theatres.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)localTheatresForMovie:(SEAMovie *)movie;
/**
 *  Returns instances of theatres in the selected city that have given movies currently playing.
 *
 *  @param movies Movies that should be playing in the theatres.
 *
 *  @return Array of theatre instances.
 */
- (NSArray *)localTheatresForMovies:(NSArray *)movies;
/**
 *  Returns instances of showtimes in the selected city that correspond to given movies.
 *
 *  @param movies Movies showtimes should belong to.
 *
 *  @return Array of showtime instances.
 */
- (NSArray *)localShowtimesForMovies:(NSArray *)movies;
/**
 *  Returns instances of showtimes in the selected city that correspond to the given movie.
 *
 *  @param movies Movie showtimes should belong to.
 *
 *  @return Array of showtime instances.
 */
- (NSArray *)localShowtimesForMovie:(SEAMovie *)movie;
/**
 *  Returns the minimum average rating for now playing movies.
 *
 *  @return Minimum average rating.
 */
- (CGFloat)minimumRatingForNowPlayingMovies;
/**
 *  Returns the maximum average rating for now playing movies.
 *
 *  @return Maximum average rating.
 */
- (CGFloat)maximumRatingForNowPlayingMovies;
/**
 *  Returns the minimum runtime for now playing movies.
 *
 *  @return Minimum runtime in seconds.
 */
- (NSTimeInterval)minimumRuntimeForNowPlayingMovies;
/**
 *  Returns the maximum runtime for now playing movies.
 *
 *  @return Maximum runtime in seconds.
 */
- (NSTimeInterval)maximumRuntimeForNowPlayingMovies;
/**
 *  Sorts movies by the current sorting option.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
- (NSArray *)sortedMovies:(NSArray *)movies;
/**
 *  Sorts movies by the count of their showtimes.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
+ (NSArray *)moviesSortedByShowtimes:(NSArray *)movies;
/**
 *  Sorts movies alphabetically by their titles.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
+ (NSArray *)moviesSortedAlphabetically:(NSArray *)movies;
/**
 *  Sorts movies by their popularity index.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
+ (NSArray *)moviesSortedByPopularity:(NSArray *)movies;
/**
 *  Sorts movies by their average ratings.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
+ (NSArray *)moviesSortedByRating:(NSArray *)movies;
/**
 *  Sorts movies by their runtimes.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
+ (NSArray *)moviesSortedByRuntime:(NSArray *)movies;
/**
 *  Sorts movies by the number of days to the their first showtimes.
 *
 *  @param movies Movies to sort.
 *
 *  @return Array of sorted movie instances.
 */
+ (NSArray *)moviesSortedByDate:(NSArray *)movies;
/**
 *  Sorts theatres by the current sorting option.
 *
 *  @param movies Theatres to sort.
 *
 *  @return Array of sorted theatre instances.
 */
- (NSArray *)sortedTheatres:(NSArray *)theatres;
/**
 *  Sorts theatres alphabetically by their names.
 *
 *  @param theatres Theatres to sort.
 *
 *  @return Array of sorted theatre instances.
 */
+ (NSArray *)theatresSortedAlphabetically:(NSArray *)theatres;
/**
 *  Sorts theatres by the distance to them from the current location.
 *
 *  @param theatres Theatres to sort.
 *
 *  @return Array of sorted theatre instances.
 */
+ (NSArray *)theatresSortedByDistance:(NSArray *)theatres;
/**
 *  Sorts theatres by the number of showtimes of the given movie.
 *
 *  @param theatres Theatres to sort.
 *
 *  @return Array of sorted theatre instances.
 */
+ (NSArray *)theatresSortedByShowtimes:(NSArray *)theatres movie:(SEAMovie *)movie;
/**
 *  Sorts theatres by the total count of their showtimes.
 *
 *  @param theatres Theatres to sort.
 *  @param movie Movie to get showtimes for.
 *
 *  @return Array of sorted theatre instances.
 */
+ (NSArray *)theatresSortedByShowtimesCount:(NSArray *)theatres;
/**
 *  Sorts theatres by the average adult ticket price.
 *
 *  @param theatres Theatres to sort.
 *
 *  @return Array of sorted theatre instances.
 */
+ (NSArray *)theatresSortedByPrice:(NSArray *)theatres;
/**
 *  Sorts showtimes by the amount of time left till their beginning.
 *
 *  @param showtimes Showtimes to sort.
 *
 *  @return Array of sorted showtime instances.
 */
+ (NSArray *)showtimesSortedByTime:(NSArray *)showtimes;
/**
 *  Sorts news entries by their publication date.
 *
 *  @param news News entries to sort.
 *
 *  @return Array of sorted news entry instances.
 */
+ (NSArray *)newsSortedByDate:(NSArray *)news;
/**
 *  Filters movies by the current sorting option.
 *
 *  @param movies Movies to filter.
 *
 *  @return Array of filtered movie instances.
 */
- (NSArray *)filteredMovies:(NSArray *)movies;
/**
 *  Filters movies by the given average rating.
 *
 *  @param movies Movies to filter.
 *  @param rating Minimum average rating necessary to pass the filter.
 *
 *  @return Array of filtered movie instances.
 */
+ (NSArray *)filterMovies:(NSArray *)movies rating:(NSInteger)rating;
/**
 *  Filters movies by the given runtime.
 *
 *  @param movies Movies to filter.
 *  @param runtime Maximum runtime necessary to pass the filter.
 *
 *  @return Array of filtered movie instances.
 */
+ (NSArray *)filterMovies:(NSArray *)movies runtime:(NSTimeInterval)runtime;
/**
 *  Filters movies by given genres.
 *
 *  @param movies Movies to filter.
 *  @param genres Array of genres that a movie needs to contains to pass the filter.
 *
 *  @return Array of filtered movie instances.
 */
+ (NSArray *)filterMovies:(NSArray *)movies genres:(NSArray *)genres;
/**
 *  Filters movies by a maximum age limit (16 by default).
 *
 *  @param movies Movies to filter.
 *
 *  @return Array of filtered movie instances.
 */
+ (NSArray *)filterMoviesForChildren:(NSArray *)movies;
/**
 *  Filters movies by a given release date.
 *
 *  @param movies Movies to filter.
 *  @param date Date on which a movie has to be released to pass the filter.
 *
 *  @return Array of filtered movie instances.
 */
+ (NSArray *)filterMovies:(NSArray *)movies date:(NSDate *)date;
/**
 *  Filters showtimes by a given date.
 *
 *  @param showtimes Showtimes to filter.
 *  @param timeInterval Date at which the showtimes has to start to pass the filter.
 *
 *  @return Array of filtered showtime instances.
 */
+ (NSArray *)filterShowtimes:(NSArray *)showtimes date:(NSDate *)date;
/**
 *  Filters showtimes by a given theatre id.
 *
 *  @param showtimes Showtimes to filter.
 *  @param theatreId Id of the theatre that showtimes need to belong to to pass the filter.
 *
 *  @return Array of filtered showtime instances.
 */
+ (NSArray *)filterShowtimes:(NSArray *)showtimes theatreId:(NSInteger)theatreId;
/**
 *  Filters showtimes by a given movie id.
 *
 *  @param showtimes Showtimes to filter.
 *  @param movieId Id of the movie that showtimes need to belong to to pass the filter.
 *
 *  @return Array of filtered showtime instances.
 */
+ (NSArray *)filterShowtimes:(NSArray *)showtimes movieId:(NSInteger)movieId;
/**
 *  Filters showtimes by checking if they have already passed. New day starts at 5 in the morning.
 *
 *  @param showtimes Showtimes to filter.
 *
 *  @return Array of filtered showtime instances.
 */
+ (NSArray *)filterPassedShowtimes:(NSArray *)showtimes;
/**
 *  Checks if the time interval has already passed. New day starts at 5 in the morning.
 *
 *  @param date Date to check.
 *
 *  @return BOOL whether or not the given time interval has passed.
 */
+ (BOOL)hasPassed:(NSDate *)date;
/**
 *  Rerturns a time interval from a given sting.
 *
 *  @param string String in format "HH:mm".
 *
 *  @return NSTimeInterval object.
 */
- (NSTimeInterval)timeIntervalFromString:(NSString *)string;

#pragma mark Properties

/**
 *  Contains movies currently playing in all cities.
 */
@property (nonatomic) NSMutableArray *nowPlayingMovies;
/**
 *  Contains now playing movies that are featured.
 */
@property (nonatomic) NSArray *featuredMovies;
/**
 *  Contains all movies coming soon to the cinemas.
 */
@property (nonatomic) NSMutableArray *comingSoonMovies;
/**
 *  Contains theatres of all cities.
 */
@property (nonatomic) NSMutableArray *theatres;
/**
 *  Contains all showtimes sorted by theatre ids.
 */
@property (nonatomic) NSMutableDictionary *showtimes;
/**
 *  Contains news entries centered about movies.
 */
@property (nonatomic) NSMutableArray *news;
/**
 *  Indicates if all data is loaded.
 */
@property (nonatomic) BOOL loaded;
/**
 *  Date to filter showtimes by.
 */
@property (nonatomic, readonly) NSDate *selectedDate;
/**
 *  Index of the date to filter showtimes by.
 */
@property (nonatomic) SEAShowtimesDate selectedDayIndex;
/**
 *  Formatter for dates with ALA time.
 */
@property (nonatomic) NSDateFormatter *dateFormatter;

@end
