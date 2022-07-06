#import "SEAModel.h"

@interface SEANewsEntry : SEAModel <NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSInteger id;
@property (nonatomic, readonly) NSURL *link;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSURL *imageUrl;

#pragma mark Methods

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
