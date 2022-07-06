#import "NSString+SEAHelpers.h"

@implementation NSString (SEAHelpers)

+ (instancetype)getNumEnding:(NSInteger)number endings:(NSArray *)endings {
  NSString *ending;
  number = number % 100;
  if (number >= 11 && number <= 19) {
    ending = endings[2];
  } else {
    int i = number % 10;
    switch (i) {
      case 1:
        ending = endings[0];
        break;
      case 2:
        ending = endings[1];
        break;
      case 3:
        ending = endings[1];
        break;
      case 4:
        ending = endings[1];
        break;
      default:
        ending = endings[2];
        break;
    }
  }
  return ending;
}

@end
