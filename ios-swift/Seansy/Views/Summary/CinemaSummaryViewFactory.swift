import Hue
import Kingfisher
import RxSwift
import UIKit

final class CinemaSummaryViewFactory: SummaryViewFactory {

  // MARK: Public constants

  static let height: CGFloat = 100

  // MARK: Private properties

  private lazy var titleLabel = UILabel().then {
    $0.autoresizingMask = .FlexibleTopMargin
    $0.textColor = .whiteColor()
    $0.font = .lightFontOfSize(20)
  }

  // MARK: Initialization

  override init(bounds: CGRect) {
    super.init(bounds: bounds)

    imageView.contentMode = .ScaleAspectFill
    imageView.alpha = 0.75
    imageView.gradientView.hidden = false
    imageView.gradientType = .Backdrop(GradientType.defaultEndColor)
    titleLabel.frame = CGRect(x: 10, y: 0, width: bounds.width - 20, height: 0)
  }

  // MARK: SummaryViewFactory

  override var subviews: [UIView] { return super.subviews + [titleLabel] }

  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
  }

  // MARK: Public methods

  func setInfoAlpha(alpha: CGFloat) {
    titleLabel.alpha = alpha
  }

  func configure(cinema: Cinema) {
    titleLabel.text = cinema.name
    titleLabel.adjustFontSize(2, minSize: 18)
    titleLabel.bottom = bounds.height - 10

    if let imageUrl = cinema.photoUrl {
      imageView.kf_setImageWithURL(
        imageUrl,
        placeholderImage: nil,
        optionsInfo: [.Transition(ImageTransition.Fade(0.3))]
      )
    } else {
      imageView.image = UIImage(.MovieBackdropPlaceholder)
    }
  }
}
