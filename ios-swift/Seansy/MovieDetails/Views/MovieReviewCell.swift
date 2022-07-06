import Hue
import Reusable
import Sugar
import UIKit

final class MovieReviewCell: UICollectionViewCell, Reusable {

  // MARK: Private properties

  private lazy var iconImageView: UIImageView = {
    return UIImageView(frame: CGRect(width: 50, height: self.height)).then {
      $0.optimize()
      $0.tintColor = .whiteColor()
      $0.contentMode = .Center
    }
  }()
  private lazy var textLabelWrapper: UIView = {
    return UIView(frame: CGRect(size: self.size, edgeInsets: UIEdgeInsets().left(self.iconImageView.right)))
      .then { $0.optimize() }
  }()
  private lazy var textLabel: UILabel = {
    return UILabel(frame: self.textLabelWrapper.bounds.insetBy(dx: 10, dy: 10)).then {
      $0.optimize()
      $0.backgroundColor = UIColor.blackColor().alpha(0.01)
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(14)
      $0.numberOfLines = 0
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    optimize()
    contentView.layer.borderWidth = 2
    contentView.addSubview(iconImageView)

    textLabelWrapper.addSubview(textLabel)
    contentView.addSubview(textLabelWrapper)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionReusableView

  override func prepareForReuse() {
    textLabel.text = nil
  }

  // MARK: Public methods

  func configure(review: MoviePressReview) {
    iconImageView.image = UIImage(review.asset).icon
    iconImageView.backgroundColor = review.color
    contentView.layer.borderColor = review.color.CGColor
    textLabel.text = review.text

    textLabel.sizeToFitInHeight(textLabelWrapper.height)
    if textLabel.height > textLabelWrapper.height - 20 {
      textLabelWrapper.layer.mask = [.blackColor(), .clearColor()].gradient().then {
        $0.locations = [1.0 - 25 / textLabelWrapper.height, 1.0 - 5 / textLabelWrapper.height]
        $0.frame = textLabelWrapper.bounds
      }
    } else {
      textLabelWrapper.layer.mask = nil
    }
  }
}
