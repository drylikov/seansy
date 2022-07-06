//
//  Copyright (c) 2015 Román Aguirre, 2015 Ayan Yenbekbay.
//

#import "DRViewSlideAction.h"

@implementation DRViewSlideAction

#pragma mark Initializaton

+ (instancetype)actionForFraction:(CGFloat)fraction {
	return [[self alloc] initWithFraction:fraction];
}

- (instancetype)initWithFraction:(CGFloat)fraction {
    self = [super init];
    if (!self) return nil;
    
    _fraction = fraction;
    _activeBackgroundColor = [UIColor blueColor];
    _inactiveBackgroundColor = [UIColor colorWithWhite:0.94f alpha:1];
    _activeColor = _inactiveColor = [UIColor whiteColor];
    _iconMargin = 25;

	return self;
}

#pragma mark Setters & getters

- (void)setElasticity:(CGFloat)elasticity {
	_elasticity = (CGFloat)(fabs(elasticity) * [self fractionSign]);
}

- (CGFloat)fractionSign {
	return (CGFloat)(self.fraction / fabs(self.fraction));
}

@end
