#import "CLLocation+SEAHelpers.h"

static NSTimeInterval const kRecentLocationMaximumElapsedTimeInterval = 5;

@implementation CLLocation (SEAHelpers)

- (BOOL)isStale {
  return [self elapsedTimeInterval] > kRecentLocationMaximumElapsedTimeInterval;
}

- (NSTimeInterval)elapsedTimeInterval {
  return [[NSDate date] timeIntervalSinceDate:self.timestamp];
}

@end
