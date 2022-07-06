import Sugar
import UIKit

final class MovieBackdropImageView: UIView {

  // Inputs

  let imageHeight: CGFloat

  // MARK: Public properties

  private(set) lazy var gradientView: UIImageView = {
    return UIImageView(frame:  CGRect(width: self.width, height: self.imageHeight)).then { $0.optimize() }
  }()
  let imageViews: [UIImageView]

  // MARK: Initialization

  init(frame: CGRect, imageHeight: CGFloat) {
    self.imageHeight = imageHeight
    imageViews = Array(0..<5).map { index in
      return UIImageView(frame: CGRect(width: frame.width, height: imageHeight)).then {
        $0.contentMode = .ScaleAspectFill
        $0.alpha = index == 0 ? 1 : 0
        $0.clipsToBounds = true
      }
    }
    super.init(frame: frame)

    backgroundColor = BackdropColors.defaultBackgroundColor
    alpha = 0.75
    clipsToBounds = true
    imageViews.forEach { addSubview($0) }
    addSubview(gradientView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func updateBlur(ratio: CGFloat) {
    let rawIndex = CGFloat(self.imageViews.count - 1) * ratio
    let lowIndex = Int(floor(rawIndex))
    let highIndex = Int(ceil(rawIndex))

    imageViews.enumerate().forEach { index, imageView in
      switch index {
      case lowIndex: imageView.alpha = 1
      case highIndex: imageView.alpha = 1 - (CGFloat(index) - rawIndex)
      default: imageView.alpha = 0
      }
    }
  }

  func updateImageViews(image: UIImage) {
    let inputImage = CIImage(image: image)!
    let blurFilter = CIFilter(name: "CIGaussianBlur")!.then { $0.setValue(inputImage, forKey: kCIInputImageKey) }

    imageViews.enumerate().forEach { index, imageView in
      if index == 0 {
        imageView.image = image
      } else {
        let radius = round(Float(index + 1) / Float(imageViews.count) * 12)

        dispatch(queue: .Interactive) {
          let context = CIContext()
          let blurFilter = blurFilter.copy()
          blurFilter.setValue(NSNumber(float: radius), forKey: kCIInputRadiusKey)
          let blurredCIImage = blurFilter.valueForKey(kCIOutputImageKey) as! CIImage
          let blurredCGImage = context.createCGImage(blurredCIImage, fromRect: inputImage.extent)
          dispatch { imageView.image = UIImage(CGImage: blurredCGImage) }
        }
      }
    }
  }
}
