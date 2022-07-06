@interface SEAModel : NSObject

- (NSString *)stringFromDictionary:(NSDictionary *)dictionary key:(NSString *)key;
- (NSArray *)arrayFromDictionary:(NSDictionary *)dictionary key:(NSString *)key;

@end
