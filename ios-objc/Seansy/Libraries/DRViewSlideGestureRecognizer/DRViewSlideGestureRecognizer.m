//
//  Copyright (c) 2015 Román Aguirre, 2015 Ayan Yenbekbay.
//

#import "DRViewSlideGestureRecognizer.h"

#import "DRViewSlideActionView.h"
#import "UIView+AYUtils.h"

#define ANIMATION_TIME 0.4f

@interface DRViewSlideGestureRecognizer ()

@property (nonatomic) NSMutableArray *leftActions;
@property (nonatomic) NSMutableArray *rightActions;
@property (nonatomic) DRViewSlideActionView *actionView;

@end

@implementation DRViewSlideGestureRecognizer

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.delegate = self;
    [self addTarget:self action:@selector(handlePan)];
    
    self.leftActions = [NSMutableArray new];
    self.rightActions = [NSMutableArray new];
    
    self.actionView = [DRViewSlideActionView new];
	
	return self;
}

#pragma mark Public

- (void)addActions:(NSArray *)actions {
	safeFor(actions, ^(DRViewSlideAction *a) {
		if (a.fraction > 0) {
			[self.leftActions addObject:a];
		} else if (a.fraction < 0) {
			[self.rightActions addObject:a];
		}
	});
}

void safeFor(id arrayOrObject, void (^forBlock)(id object)) {
	if ([arrayOrObject isKindOfClass:[NSArray class]]) {
		for (id object in arrayOrObject) {
			forBlock(object);
		}
	} else {
		forBlock(arrayOrObject);
	}
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	CGPoint velocity = [self velocityInView:self.view];
	return fabs(velocity.x) > fabs(velocity.y);
}

- (void)handlePan {
	if (self.state == UIGestureRecognizerStateBegan) {
		[self sortActions];
		[self.view.superview insertSubview:self.actionView atIndex:0];
		self.actionView.frame = self.view.frame;
		self.actionView.active = NO;
	} else if (self.state == UIGestureRecognizerStateChanged) {
		[self updateViewPosition];
		if ([self isActiveForCurrentViewPosition] != self.actionView.active) {
			self.actionView.active = [self isActiveForCurrentViewPosition];
			if (self.actionView.action.didChangeStateBlock) self.actionView.action.didChangeStateBlock(self.actionView.action, self.actionView.isActive);
		}
		if ([self actionForCurrentViewPosition] != self.actionView.action) {
			self.actionView.action = [self actionForCurrentViewPosition];
		}
	} else if (self.state == UIGestureRecognizerStateEnded) {
		[self performAction];
	}
}

#pragma mark Private

- (CGFloat)currentHorizontalTranslation {
	CGFloat horizontalTranslation = [self translationInView:self.view].x;
	if ((horizontalTranslation > 0 && self.leftActions.count == 0) || (horizontalTranslation < 0 && self.rightActions.count == 0)) {
		horizontalTranslation = 0;
	}
	return horizontalTranslation;
}

- (void)sortActions {
	[self.leftActions sortUsingComparator:^NSComparisonResult(DRViewSlideAction *a1, DRViewSlideAction *a2) {
		return a1.fraction > a2.fraction ? NSOrderedDescending : NSOrderedAscending;
	}];
	[self.rightActions sortUsingComparator:^NSComparisonResult(DRViewSlideAction *a1, DRViewSlideAction *a2) {
		return a1.fraction > a2.fraction ? NSOrderedAscending : NSOrderedDescending;
	}];
}

- (CGFloat)fractionForCurrentViewPosition {
	return self.view.left / self.view.width;
}

- (NSArray *)actionsForCurrentViewPosition {
	return [self fractionForCurrentViewPosition] >= 0 ? self.leftActions : self.rightActions;
}

- (DRViewSlideAction *)actionForCurrentViewPosition {
	DRViewSlideAction *action;
	NSArray *actions = [self actionsForCurrentViewPosition];
	for (DRViewSlideAction *a in actions) {
		if (fabs([self fractionForCurrentViewPosition]) > fabs(a.fraction)) {
			action = a;
		} else {
			break;
		}
	}
	if (!action) action = [actions firstObject];
	return action;
}

- (BOOL)isActiveForCurrentViewPosition {
	return fabs([self fractionForCurrentViewPosition]) >= fabs([self actionForCurrentViewPosition].fraction);
}

- (void)updateViewPosition {
	CGFloat horizontalTranslation = [self currentHorizontalTranslation];
	DRViewSlideAction *lastAction = [[self actionsForCurrentViewPosition] lastObject];
	if (lastAction.elasticity != 0) {
		CGFloat li = self.view.width * lastAction.fraction;
		if (fabs(horizontalTranslation) >= fabs(li)) {
			CGFloat lf = li + lastAction.elasticity;
            horizontalTranslation = (CGFloat)(atanf((float)(tanf((float)((M_PI * li) / (2 * lf))) * (horizontalTranslation / li))) * (2 * lf / M_PI));
		}
	}
	[self translateViewHorizontally:horizontalTranslation];
	[self.actionView cellDidUpdatePosition:self.view];
}

- (void)translateViewHorizontally:(CGFloat)horizontalTranslation {
    self.view.centerX = self.view.width/2 + horizontalTranslation;
}

- (void)translateViewHorizontally:(CGFloat)horizontalTranslation animatedlyWithDuration:(NSTimeInterval)duration damping:(CGFloat)damping completion:(void (^)(BOOL finished))completion {
	[UIView animateWithDuration:duration delay:0 usingSpringWithDamping:damping initialSpringVelocity:1 options:kNilOptions animations:^{
		[self translateViewHorizontally:horizontalTranslation];
	} completion:completion];
}

- (void)performAction {
	if (self.actionView.active) {
		CGFloat horizontalTranslation = [self horizontalTranslationForActionBehavior];
        if (self.actionView.action.willTriggerBlock) {
            self.actionView.action.willTriggerBlock();
        }
		[self translateViewHorizontally:horizontalTranslation animatedlyWithDuration:ANIMATION_TIME damping:1 completion:^(BOOL finished) {
			if (self.actionView.action.behavior == DRViewSlideActionPushBehavior) {
				[self dismissActionView];
			} else {
				[self.actionView removeFromSuperview];
			}
            if (self.actionView.action.didTriggerBlock) {
                self.actionView.action.didTriggerBlock();
            }
		}];
	} else {
		[self translateViewHorizontally:0 animatedlyWithDuration:ANIMATION_TIME damping:0.65f completion:^(BOOL finished) {
			[self.actionView removeFromSuperview];
		}];
	}
}

- (CGFloat)horizontalTranslationForActionBehavior {
	return self.actionView.action.behavior == DRViewSlideActionPullBehavior ? 0 : (CGFloat)(self.view.width * (self.actionView.action.fraction / fabs(self.actionView.action.fraction)));
}

- (void)dismissActionView {
	[UIView animateWithDuration:0.3f animations:^{
		self.actionView.alpha = 0;
	} completion:^(BOOL finished) {
		[self.actionView removeFromSuperview];
		self.actionView.alpha = 1;
	}];
}

@end
