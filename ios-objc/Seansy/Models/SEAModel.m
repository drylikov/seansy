#import "SEAModel.h"

@implementation SEAModel

- (NSString *)stringFromDictionary:(NSDictionary *)dictionary key:(NSString *)key {
  NSString *string;
  id object = dictionary[key];
  if (object && object != [NSNull null]) {
    string = [[NSString alloc] initWithFormat:@"%@", object];
    if (string.length == 0) {
      string = nil;
    }
  }
  return string;
}

- (NSArray *)arrayFromDictionary:(NSDictionary *)dictionary key:(NSString *)key {
  NSArray *array;
  id object = dictionary[key];
  if (object && object != [NSNull null]) {
    array = [[[NSString alloc] initWithFormat:@"%@", object] componentsSeparatedByString:@","];
    if ([(NSString *)array[0] length] == 0) {
      array = nil;
    }
  }
  return array;
}

@end
