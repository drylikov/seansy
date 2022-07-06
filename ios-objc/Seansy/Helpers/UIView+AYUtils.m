//
//  Copyright (c) 2011 Charcoal Design, 2015 Ayan Yenbekbay.
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/ViewUtils
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "UIView+AYUtils.h"
#import <QuartzCore/QuartzCore.h>

#pragma GCC diagnostic ignored "-Wgnu"

@implementation UIView (AYUtils)

#pragma mark Frame Accessors

- (CGPoint)origin {
  return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
  CGRect frame = self.frame;

  frame.origin = origin;
  self.frame = frame;
}

- (CGSize)size {
  return self.frame.size;
}

- (void)setSize:(CGSize)size {
  CGRect frame = self.frame;

  frame.size = size;
  self.frame = frame;
}

- (CGFloat)top {
  return self.origin.y;
}

- (void)setTop:(CGFloat)top {
  CGRect frame = self.frame;

  frame.origin.y = top;
  self.frame = frame;
}

- (CGFloat)left {
  return self.origin.x;
}

- (void)setLeft:(CGFloat)left {
  CGRect frame = self.frame;

  frame.origin.x = left;
  self.frame = frame;
}

- (CGFloat)right {
  return self.left + self.width;
}

- (void)setRight:(CGFloat)right {
  CGRect frame = self.frame;

  frame.origin.x = right - frame.size.width;
  self.frame = frame;
}

- (CGFloat)bottom {
  return self.top + self.height;
}

- (void)setBottom:(CGFloat)bottom {
  CGRect frame = self.frame;

  frame.origin.y = bottom - frame.size.height;
  self.frame = frame;
}

- (CGFloat)width {
  return self.size.width;
}

- (void)setWidth:(CGFloat)width {
  CGRect frame = self.frame;

  frame.size.width = width;
  self.frame = frame;
}

- (CGFloat)height {
  return self.size.height;
}

- (void)setHeight:(CGFloat)height {
  CGRect frame = self.frame;

  frame.size.height = height;
  self.frame = frame;
}

- (CGFloat)centerX {
  return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
  self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
  return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
  self.center = CGPointMake(self.center.x, centerY);
}

#pragma mark Bounds Accessors

- (CGSize)boundsSize {
  return self.bounds.size;
}

- (void)setBoundsSize:(CGSize)size {
  CGRect bounds = self.bounds;

  bounds.size = size;
  self.bounds = bounds;
}

- (CGFloat)boundsWidth {
  return self.boundsSize.width;
}

- (void)setBoundsWidth:(CGFloat)width {
  CGRect bounds = self.bounds;

  bounds.size.width = width;
  self.bounds = bounds;
}

- (CGFloat)boundsHeight {
  return self.boundsSize.height;
}

- (void)setBoundsHeight:(CGFloat)height {
  CGRect bounds = self.bounds;

  bounds.size.height = height;
  self.bounds = bounds;
}

#pragma mark Content Getters

- (CGRect)contentBounds {
  return CGRectMake(0.0f, 0.0f, self.boundsWidth, self.boundsHeight);
}

- (CGPoint)contentCenter {
  return CGPointMake(self.boundsWidth / 2.0f, self.boundsHeight / 2.0f);
}

#pragma mark Additional Frame Setters

- (void)setLeft:(CGFloat)left right:(CGFloat)right {
  CGRect frame = self.frame;

  frame.origin.x = left;
  frame.size.width = right - left;
  self.frame = frame;
}

- (void)setWidth:(CGFloat)width right:(CGFloat)right {
  CGRect frame = self.frame;

  frame.origin.x = right - width;
  frame.size.width = width;
  self.frame = frame;
}

- (void)setTop:(CGFloat)top bottom:(CGFloat)bottom {
  CGRect frame = self.frame;

  frame.origin.y = top;
  frame.size.height = bottom - top;
  self.frame = frame;
}

- (void)setHeight:(CGFloat)height bottom:(CGFloat)bottom {
  CGRect frame = self.frame;

  frame.origin.y = bottom - height;
  frame.size.height = height;
  self.frame = frame;
}

@end
