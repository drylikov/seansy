#import "SEAStarRatingView.h"

@implementation SEAStarRatingView {
  CGFloat _minimumValue;
  CGFloat _maximumValue;
  CGFloat _value;
}

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  [self setBackgroundColor:[UIColor clearColor]];
  if (!self) {
    return nil;
  }

  self.minimumValue = 1;
  self.maximumValue = 5;
  self.value = 0;
  self.spacing = 5;

  return self;
}

#pragma mark UIView

- (CGSize)intrinsicContentSize {
  CGFloat height = 44;
  return CGSizeMake(self.maximumValue * height + (self.maximumValue + 1) * self.spacing, height);
}

- (void)setNeedsLayout {
  [super setNeedsLayout];
  [self setNeedsDisplay];
}

#pragma mark Setters & getters

- (CGFloat)minimumValue {
  return MAX(_minimumValue, 0);
}

- (void)setMinimumValue:(CGFloat)minimumValue {
  if (_minimumValue != minimumValue) {
    _minimumValue = minimumValue;
    [self setNeedsDisplay];
  }
}

- (CGFloat)maximumValue {
  return MAX(self.minimumValue, _maximumValue);
}

- (void)setMaximumValue:(CGFloat)maximumValue {
  if (_maximumValue != maximumValue) {
    _maximumValue = maximumValue;
    [self setNeedsDisplay];
    [self invalidateIntrinsicContentSize];
  }
}

- (CGFloat)value {
  return MIN(MAX(_value, self.minimumValue), self.maximumValue);
}

- (void)setValue:(CGFloat)value {
  if (_value != value) {
    _value = value;
    [self setNeedsDisplay];
  }
}

- (void)setSpacing:(CGFloat)spacing {
  _spacing = MAX(spacing, 0);
  [self setNeedsDisplay];
}

- (void)setAllowsHalfStars:(BOOL)allowsHalfStars {
  if (_allowsHalfStars != allowsHalfStars) {
    _allowsHalfStars = allowsHalfStars;
    [self setNeedsDisplay];
  }
}

#pragma mark Drawing

- (void)drawStarWithFrame:(CGRect)frame tintColor:(UIColor *)tintColor highlighted:(BOOL)highlighted {
  UIBezierPath *starShapePath = UIBezierPath.bezierPath;

  [starShapePath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 0.62723f * CGRectGetWidth(frame),
                                         CGRectGetMinY(frame) + 0.37309f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.02500f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.37292f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.37309f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.02500f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.39112f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.30504f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.62908f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.20642f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.97500f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.78265f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.79358f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.97500f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.69501f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.62908f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.97500f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.39112f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.62723f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.37309f * CGRectGetHeight(frame))];
  [starShapePath closePath];
  starShapePath.miterLimit = 4;

  if (highlighted) {
    [tintColor setFill];
    [starShapePath fill];
  }

  [tintColor setStroke];
  starShapePath.lineWidth = 1;
  [starShapePath stroke];
}

- (void)drawHalfStarWithFrame:(CGRect)frame tintcolor:(UIColor *)tintColor highlighted:(BOOL)highlighted {
  UIBezierPath *starShapePath = UIBezierPath.bezierPath;

  [starShapePath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000f * CGRectGetWidth(frame),
                                         CGRectGetMinY(frame) + 0.02500f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.37292f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.37309f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.02500f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.39112f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.30504f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.62908f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.20642f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.97500f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.78265f * CGRectGetHeight(frame))];
  [starShapePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000f * CGRectGetWidth(frame),
                                            CGRectGetMinY(frame) + 0.02500f * CGRectGetHeight(frame))];
  [starShapePath closePath];
  starShapePath.miterLimit = 4;

  if (highlighted) {
    [tintColor setFill];
    [starShapePath fill];
  }

  [tintColor setStroke];
  starShapePath.lineWidth = 1;
  [starShapePath stroke];
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
  CGContextFillRect(context, rect);

  CGFloat availableWidth = rect.size.width - (self.spacing * (self.maximumValue + 1));
  CGFloat cellWidth = (availableWidth / self.maximumValue);
  CGFloat starSide = (cellWidth <= rect.size.height) ? cellWidth : rect.size.height;
  for (int idx = 0; idx < self.maximumValue; idx++) {
    CGPoint center = CGPointMake(cellWidth * idx + cellWidth / 2 + self.spacing * (idx + 1), rect.size.height / 2);
    CGRect frame = CGRectMake(center.x - starSide / 2, center.y - starSide / 2, starSide, starSide);
    BOOL highlighted = (idx + 1 <= ceil(self.value));
    BOOL halfStar = highlighted ? (idx + 1 > self.value) : NO;
    if (halfStar && self.allowsHalfStars) {
      [self drawStarWithFrame:frame tintColor:self.tintColor highlighted:NO];
      [self drawHalfStarWithFrame:frame tintcolor:self.tintColor highlighted:highlighted];
    } else {
      [self drawStarWithFrame:frame tintColor:self.tintColor highlighted:highlighted];
    }
  }
}

@end
