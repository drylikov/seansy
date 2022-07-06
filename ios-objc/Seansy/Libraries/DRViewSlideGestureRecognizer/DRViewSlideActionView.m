//
//  Copyright (c) 2015 Román Aguirre, 2015 Ayan Yenbekbay.
//

#import "DRViewSlideActionView.h"

#import "DRViewSlideAction.h"
#import "SEAConstants.h"
#import "UIFont+SEASizes.h"
#import "UIView+AYUtils.h"

@interface DRViewSlideActionView ()

@property (nonatomic) UIImageView *iconImageView;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation DRViewSlideActionView

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.iconImageView = [UIImageView new];
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
	
	return self;
}

#pragma mark Public

- (void)cellDidUpdatePosition:(UIView *)view {
	[self updateIconImageViewFrame];
    CGFloat alpha = (CGFloat)(fabs(view.left) / (self.iconImageView.image.size.width + self.action.iconMargin + 10));
	self.iconImageView.alpha = alpha;
    self.titleLabel.alpha = alpha;
}

#pragma mark Private

- (void)tint {
    self.iconImageView.tintColor = self.active ? self.action.activeColor : self.action.inactiveColor;
    self.titleLabel.textColor = self.active ? self.action.activeColor : self.action.inactiveColor;
    self.backgroundColor = self.active ? self.action.activeBackgroundColor : self.action.inactiveBackgroundColor;
}

- (void)updateIconImageViewFrame {
    self.iconImageView.frame = CGRectMake(self.action.iconMargin, 0, self.iconImageView.image.size.width, self.iconImageView.image.size.height);
    self.iconImageView.centerY = self.height / 2;
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectMake(self.iconImageView.right + 10, 0, self.titleLabel.width, self.height);
}

#pragma mark Setters & getters

- (void)setAction:(DRViewSlideAction *)action {
	_action = action;
	
	self.iconImageView.image = [action.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = action.title;
	
	[self tint];
	[self updateIconImageViewFrame];
}

- (void)setActive:(BOOL)active {
	if (_active != active) {
		_active = active;
		
		[self tint];
	}
}

@end
