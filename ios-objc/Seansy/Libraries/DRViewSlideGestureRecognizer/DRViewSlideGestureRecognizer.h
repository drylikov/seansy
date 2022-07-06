//
//  Copyright (c) 2015 Román Aguirre, 2015 Ayan Yenbekbay.
//

#import "DRViewSlideAction.h"
#import <UIKit/UIKit.h>

@interface DRViewSlideGestureRecognizer : UIPanGestureRecognizer <UIGestureRecognizerDelegate>

- (void)addActions:(id)actions;

@end
