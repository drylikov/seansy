import UIKit

let xLens = Lens<CGRect, CGFloat>(from: { $0.origin.x }, to: {
  CGRect(x: $0, y: $1.origin.y, width: $1.width, height: $1.height)
})

let yLens = Lens<CGRect, CGFloat>(from: { $0.origin.y }, to: {
  CGRect(x: $1.origin.x, y: $0, width: $1.width, height: $1.height)
})

let widthLens = Lens<CGRect, CGFloat>(from: { $0.width }, to: {
  CGRect(x: $1.origin.x, y: $1.origin.y, width: $0, height: $1.height)
})

let heightLens = Lens<CGRect, CGFloat>(from: { $0.height }, to: {
  CGRect(x: $1.origin.x, y: $1.origin.y, width: $1.width, height: $0)
})

let originLens = Lens<CGRect, CGPoint>(from: { $0.origin }, to: {
  CGRect(x: $0.x, y: $0.y, width: $1.width, height: $1.height)
})

let sizeLens = Lens<CGRect, CGSize>(from: { $0.size }, to: {
  CGRect(x: $1.origin.x, y: $1.origin.y, width: $0.width, height: $0.height)
})

extension CGRect {
  var center: CGPoint { return  CGPoint(x: midX, y: midY) }
  var bounds: CGRect { return originLens.to(.zero, self) }

  init(width: CGFloat, height: CGFloat, edgeInsets: UIEdgeInsets = UIEdgeInsetsZero) {
    self.init(size: CGSize(width: width, height: height), edgeInsets: edgeInsets)
  }
  init(size: CGSize, edgeInsets: UIEdgeInsets = UIEdgeInsetsZero) {
    self.init(
      x: edgeInsets.left,
      y: edgeInsets.top,
      width: size.width - edgeInsets.left - edgeInsets.right,
      height: size.height - edgeInsets.top - edgeInsets.bottom
    )
  }
}
