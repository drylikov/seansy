import Hue
import UIKit

// MARK: GradientType

enum GradientType {
  case Backdrop(UIColor), Poster

  // MARK: Public constants

  static let defaultEndColor = UIColor.blackColor().alpha(0.75)

  // MARK: Public properties

  var colors: [UIColor] {
    switch self {
    case .Backdrop(let endColor): return [.clearColor(), endColor]
    case .Poster: return [.clearColor(), GradientType.defaultEndColor]
    }
  }
  var locations: [CGFloat] {
    switch self {
    case .Backdrop: return [0.6, 1.0]
    case .Poster: return [0.4, 1.0]
    }
  }
  var size: CGSize {
    switch self {
    case .Backdrop: return CGSize(width: screenWidth, height: 200)
    case .Poster: return CGSize(width: 70, height: 100)
    }
  }
  var gradientLayer: CAGradientLayer {
    return colors.gradient().then {
      $0.locations = locations
      $0.frame = CGRect(origin: .zero, size: size)
    }
  }
}

// MARK: -

final class GradientImageView: UIImageView {

  // MARK: Public properties

  var gradientType: GradientType? {
    didSet {
      gradientView.image = gradientType.flatMap { UIImage(gradientLayer: $0.gradientLayer) }
    }
  }
  private(set) lazy var gradientView: UIImageView = {
    return UIImageView(frame: self.bounds.insetBy(dx: -2, dy: -2)).then {
      $0.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
      $0.hidden = true
    }
  }()

  // MARK: Initialization

  init() {
    super.init(frame: .zero)
    addSubview(gradientView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
