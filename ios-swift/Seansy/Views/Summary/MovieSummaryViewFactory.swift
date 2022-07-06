import Sugar
import UIKit

class MovieSummaryViewFactory: SummaryViewFactory {

  // MARK: Public constants

  static let height: CGFloat = 150

  // MARK: Public properties

  private(set) lazy var ratingStarsView: SEAStarRatingView = {
    return SEAStarRatingView().then {
      $0.tintColor = .accentColor()
      $0.hidden = true
    }
  }()
  private(set) lazy var ratingLabel: UILabel = {
    return UILabel().then {
      $0.backgroundColor = UIColor.blackColor().alpha(0.5)
      $0.textColor = .whiteColor()
      $0.textAlignment = .Center
      $0.font = .regularFontOfSize(16)
      $0.layer.cornerRadius = 3
      $0.hidden = true
    }
  }()

  // MARK: Private properties

  private lazy var usePercentRating = Cache[.usePercentRating]

  // MARK: SummaryViewFactory

  override var subviews: [UIView] { return super.subviews + [ratingStarsView, ratingLabel] }

  override func prepareForReuse() {
    super.prepareForReuse()
    ratingStarsView.hidden = true
    ratingLabel.hidden = true
    ratingLabel.textColor = .whiteColor()
  }

  // MARK: Public methods

  func setInfoAlpha(alpha: CGFloat) {
    ratingStarsView.alpha = alpha
    ratingLabel.alpha = alpha
  }

  func configure(movie: Movie) {
    if movie.releaseDate == nil && movie.averageRating > 0 {
      if usePercentRating {
        ratingLabel.textColor = movie.averageRating > 60 ? .flatGreenColor() : .flatRedColor()
        ratingLabel.text = String(format: "%.1f%%", movie.averageRating)
        ratingLabel.sizeToFit()
        ratingLabel.width += 8
        ratingLabel.height += 4
        ratingLabel.hidden = false
      } else {
        ratingStarsView.value = CGFloat(movie.averageRating) / CGFloat(20)
        ratingStarsView.hidden = false
      }
    }
  }
}
