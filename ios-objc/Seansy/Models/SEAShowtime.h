#import "SEAModel.h"
#import "SEAMovie.h"
#import "SEATheatre.h"

@interface SEAShowtime : SEAModel <NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSTimeInterval time;
@property (nonatomic, readonly) NSString *format;
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) NSDictionary *prices;
@property (nonatomic, readonly) NSInteger movieId;
@property (nonatomic, readonly) NSInteger theatreId;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSString *ticketonId;

#pragma mark Methods

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSString *)timeString;
- (NSString *)dateString;
- (BOOL)hasPassed;
- (NSString *)formatString;
- (NSAttributedString *)attributedSummaryString;
- (NSAttributedString *)attributedSummaryInlineString;
- (NSAttributedString *)attributedDetailsString;
- (NSURL *)ticketonUrl;

@end
