#import "SEANewsEntry.h"

#import "SEAConstants.h"

static NSString *const kNewsLinkKey = @"link";
static NSString *const kNewsTitleKey = @"title";
static NSString *const kNewsDateKey = @"date";
static NSString *const kNewsImageUrlKey = @"imageUrl";

@implementation SEANewsEntry

#pragma mark Initialization

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (!self) {
    return nil;
  }

  _id = [[self stringFromDictionary:dictionary key:kIdKey] integerValue];
  _link = [NSURL URLWithString:[self stringFromDictionary:dictionary key:kNewsLinkKey]];
  _title = [self stringFromDictionary:dictionary key:kNewsTitleKey];
  _date = [NSDate dateWithTimeIntervalSince1970:[[self stringFromDictionary:dictionary key:kNewsDateKey] doubleValue] / 1000];
  _imageUrl = [NSURL URLWithString:[self stringFromDictionary:dictionary key:kNewsImageUrlKey]];

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _id = [[decoder decodeObjectForKey:kIdKey] integerValue];
  _link = [decoder decodeObjectForKey:kNewsLinkKey];
  _title = [decoder decodeObjectForKey:kNewsTitleKey];
  _date = [decoder decodeObjectForKey:kNewsDateKey];
  _imageUrl = [decoder decodeObjectForKey:kNewsImageUrlKey];

  return self;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.id) forKey:kIdKey];
  [coder encodeObject:self.link forKey:kNewsLinkKey];
  [coder encodeObject:self.title forKey:kNewsTitleKey];
  [coder encodeObject:self.date forKey:kNewsDateKey];
  [coder encodeObject:self.imageUrl forKey:kNewsImageUrlKey];
}

@end
