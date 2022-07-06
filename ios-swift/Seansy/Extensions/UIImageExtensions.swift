import Hue
import UIKit

extension UIImage {
  var icon: UIImage { return imageWithRenderingMode(.AlwaysTemplate) }

  convenience init(gradientLayer: CAGradientLayer) {
    UIGraphicsBeginImageContextWithOptions(gradientLayer.frame.size, false, 0)
    gradientLayer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    self.init(CGImage: image.CGImage!)
  }

  convenience init(view: UIView) {
    UIGraphicsBeginImageContextWithOptions(view.size, true, 0)
    view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    self.init(CGImage: image.CGImage!)
  }

  func averageColorInRect(rect: CGRect) -> UIColor {
    let rgba = UnsafeMutablePointer<CUnsignedChar>.alloc(4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()!
    let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
    let context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, info.rawValue)!

    CGContextDrawImage(context, CGRect(width: 1, height: 1), CGImageCreateWithImageInRect(CGImage, rect))

    if rgba[3] > 0 {
      let alpha: CGFloat = CGFloat(rgba[3]) / 255.0
      let multiplier: CGFloat = alpha / 255.0

      return UIColor(
        red: CGFloat(rgba[0]) * multiplier,
        green: CGFloat(rgba[1]) * multiplier,
        blue: CGFloat(rgba[2]) * multiplier,
        alpha: alpha
      )
    } else {
      return UIColor(
        red: CGFloat(rgba[0]) / 255.0,
        green: CGFloat(rgba[1]) / 255.0,
        blue: CGFloat(rgba[2]) / 255.0,
        alpha: CGFloat(rgba[3]) / 255.0
      )
    }
  }
}
