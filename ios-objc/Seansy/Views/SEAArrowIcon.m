#import "SEAArrowIcon.h"

#import "UIView+AYUtils.h"

#define DEGREES_TO_RADIANS(x) ((x) * M_PI / 180)

static CGFloat const kArrowIconHorizontalCurvature = (CGFloat)DEGREES_TO_RADIANS(30);
static CGFloat const kArrowIconVerticalCurvature = (CGFloat)DEGREES_TO_RADIANS(45);
static CGFloat const kArrowIconAnimationDuration = 0.2f;

@interface SEAArrowIcon ()

@property (nonatomic) UIView *leftArrowPart;
@property (nonatomic) UIView *rightArrowPart;
@property (nonatomic) UIView *topArrowPart;
@property (nonatomic) UIView *bottomArrowPart;

@end

@implementation SEAArrowIcon

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame orientation:(SEAArrowIconOrientation)orientation {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.clipsToBounds = NO;
  self.orientation = orientation;
  self.color = [UIColor whiteColor];
  self.alpha = 0.75f;

  return self;
}

#pragma mark Private

- (UIView *)arrowPart {
  UIView *arrowPart = [UIView new];

  if (self.orientation == SEAArrowIconOrientationHorizontal) {
    arrowPart.layer.cornerRadius = self.height / 2;
  } else {
    arrowPart.layer.cornerRadius = self.width / 2;
  }

  arrowPart.layer.allowsEdgeAntialiasing = YES;
  return arrowPart;
}

- (void)pointDown {
  self.leftArrowPart.transform = CGAffineTransformMakeRotation(kArrowIconHorizontalCurvature);
  self.rightArrowPart.transform = CGAffineTransformMakeRotation(-kArrowIconHorizontalCurvature);
}

- (void)pointUp {
  self.leftArrowPart.transform = CGAffineTransformMakeRotation(-kArrowIconHorizontalCurvature);
  self.rightArrowPart.transform = CGAffineTransformMakeRotation(kArrowIconHorizontalCurvature);
}

- (void)pointRight {
  self.topArrowPart.transform = CGAffineTransformMakeRotation(-kArrowIconVerticalCurvature);
  self.bottomArrowPart.transform = CGAffineTransformMakeRotation(kArrowIconVerticalCurvature);
}

- (void)pointLeft {
  self.topArrowPart.transform = CGAffineTransformMakeRotation(kArrowIconVerticalCurvature);
  self.bottomArrowPart.transform = CGAffineTransformMakeRotation(-kArrowIconVerticalCurvature);
}

#pragma mark Public

- (void)pointDownAnimated:(BOOL)animated {
  if (animated) {
    [UIView animateWithDuration:kArrowIconAnimationDuration animations:^{
      [self pointDown];
    }];
  } else {
    [self pointDown];
  }
}

- (void)pointUpAnimated:(BOOL)animated {
  if (animated) {
    [UIView animateWithDuration:kArrowIconAnimationDuration animations:^{
      [self pointUp];
    }];
  } else {
    [self pointUp];
  }
}

- (void)pointRightAnimated:(BOOL)animated {
  if (animated) {
    [UIView animateWithDuration:kArrowIconAnimationDuration animations:^{
      [self pointRight];
    }];
  } else {
    [self pointRight];
  }
}

- (void)pointLeftAnimated:(BOOL)animated {
  if (animated) {
    [UIView animateWithDuration:kArrowIconAnimationDuration animations:^{
      [self pointLeft];
    }];
  } else {
    [self pointLeft];
  }
}

#pragma mark Setters

- (void)setColor:(UIColor *)color {
  _color = color;
  if (self.orientation == SEAArrowIconOrientationHorizontal) {
    self.rightArrowPart.backgroundColor = color;
    self.leftArrowPart.backgroundColor = color;
  } else {
    self.topArrowPart.backgroundColor = color;
    self.bottomArrowPart.backgroundColor = color;
  }
}

- (void)setOrientation:(SEAArrowIconOrientation)orientation {
  _orientation = orientation;

  if (orientation == SEAArrowIconOrientationHorizontal) {
    [self.topArrowPart removeFromSuperview];
    [self.bottomArrowPart removeFromSuperview];
    CGFloat overlap = self.height;
    self.leftArrowPart = [self arrowPart];
    self.leftArrowPart.frame = CGRectMake(0, 0, self.width / 2 + overlap, self.height);
    [self addSubview:self.leftArrowPart];
    self.rightArrowPart = [self arrowPart];
    self.rightArrowPart.frame = CGRectMake(self.width / 2 - overlap, 0, self.width / 2 + overlap, self.height);
    [self addSubview:self.rightArrowPart];
  } else {
    [self.leftArrowPart removeFromSuperview];
    [self.rightArrowPart removeFromSuperview];
    CGFloat overlap = self.width;
    self.topArrowPart = [self arrowPart];
    self.topArrowPart.frame = CGRectMake(0, 0, self.width, self.height / 2 + overlap);
    [self addSubview:self.topArrowPart];
    self.bottomArrowPart = [self arrowPart];
    self.bottomArrowPart.frame = CGRectMake(0, self.height / 2 - overlap, self.width, self.height / 2 + overlap);
    [self addSubview:self.bottomArrowPart];
  }
}

@end
