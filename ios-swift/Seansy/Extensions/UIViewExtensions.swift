import UIKit

extension UIView {
  var width: CGFloat {
    get { return frame.width }
    set { frame = widthLens.to(newValue, frame) }
  }
  var height: CGFloat {
    get { return frame.height }
    set { frame = heightLens.to(newValue, frame) }
  }
  var size: CGSize {
    get { return frame.size }
    set { frame = sizeLens.to(newValue, frame) }
  }
  var origin: CGPoint {
    get { return frame.origin }
    set { frame = originLens.to(newValue, frame) }
  }
  var centerX: CGFloat {
    get { return center.x }
    set { center = CGPoint(x: newValue, y: centerY) }
  }
  var centerY: CGFloat {
    get { return center.y }
    set { center = CGPoint(x: centerX, y: newValue) }
  }
  var left: CGFloat {
    get { return frame.origin.x }
    set { frame = xLens.to(newValue, frame) }
  }
  var right: CGFloat {
    get { return left + width }
    set { left = newValue - width }
  }
  var top: CGFloat {
    get { return frame.origin.y }
    set { frame = yLens.to(newValue, frame) }
  }
  var bottom: CGFloat {
    get { return top + height }
    set { top = newValue - height }
  }
}
