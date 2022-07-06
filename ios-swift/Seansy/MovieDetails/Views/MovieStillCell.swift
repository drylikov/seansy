import Reusable
import UIKit

final class MovieStillCell: UICollectionViewCell, Reusable {

  // MARK: Private properties

  private lazy var stillImageView: UIImageView = {
    return UIImageView(frame: self.bounds).then {
      $0.optimize()
      $0.contentMode = .ScaleAspectFill
      $0.autoresizingMask = .FlexibleWidth
    }
  }()
  private lazy var activityIndicatorView: UIActivityIndicatorView = {
    return UIActivityIndicatorView(frame: self.bounds).then {
      $0.activityIndicatorViewStyle = .White
      $0.autoresizingMask = .FlexibleWidth
      $0.startAnimating()
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    [stillImageView, activityIndicatorView].forEach { contentView.addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionReusableView

  override func prepareForReuse() {
    stillImageView.image = nil
    activityIndicatorView.startAnimating()
  }

  // MARK: Public methods

  func setImage(image: UIImage) {
    activityIndicatorView.stopAnimating()
    stillImageView.image = image
  }
}
