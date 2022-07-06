#import "SEABackdrop.h"
#import "SEAPoster.h"
#import "SEAModel.h"

typedef enum {
  SEARatingSourceKinopoisk,
  SEARatingSourceIMDB,
  SEARatingSourceRTCritics,
  SEARatingSourceRTAudience
} SEARatingSource;

@interface SEAMovie : SEAModel <NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSInteger id;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *originalTitle;
@property (nonatomic, readonly) NSInteger year;
@property (nonatomic, readonly) NSArray *ratings;
@property (nonatomic, readonly) NSArray *genre;
@property (nonatomic, readonly) NSTimeInterval runtime;
@property (nonatomic, readonly) NSInteger age;
@property (nonatomic, readonly) NSString *synopsis;
@property (nonatomic, readonly) SEAPoster *poster;
@property (nonatomic, readonly) SEABackdrop *backdrop;
@property (nonatomic, readonly) NSString *trailerId;
@property (nonatomic, readonly) NSArray *director;
@property (nonatomic, readonly) NSArray *script;
@property (nonatomic, readonly) NSArray *cast;
@property (nonatomic, readonly) NSInteger popularity;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly, getter = isFeatured) BOOL featured;
@property (nonatomic, readonly) NSArray *stills;
@property (nonatomic, readonly) NSArray *reviews;
@property (nonatomic, readonly) NSMutableDictionary *showtimes;
@property (nonatomic, readonly) NSDictionary *bonusScene;

#pragma mark Methods

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSString *)shortDateString;
- (NSString *)longDateString;
- (NSString *)genreString;
- (NSString *)runtimeString;
- (NSAttributedString *)kpRatingString;
- (NSAttributedString *)imdbRatingString;
- (NSAttributedString *)directorString;
- (NSAttributedString *)scriptString;
- (NSAttributedString *)castString;
- (NSString *)bonusSceneString;
- (NSString *)subtitle;
- (void)processShowtimes;
- (NSArray *)showtimesForTheatreId:(NSString *)theatreId;
- (CGFloat)averageRating;
- (BOOL)isPlaying;

@end
