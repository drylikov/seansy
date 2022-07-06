import NSObject_Rx
import Reusable
import RxCocoa
import RxSwift
import Sugar
import UIKit

final class MovieActorCell: UICollectionViewCell, Reusable {

  // MARK: Public properties

  private(set) lazy var photoImageView: UIImageView = {
    return UIImageView(frame: heightLens.to(self.height - 50, self.bounds)).then {
      $0.optimize()
      $0.contentMode = .ScaleAspectFill
      $0.autoresizingMask = .FlexibleWidth
    }
  }()

  // Views
  private lazy var activityIndicatorView: UIActivityIndicatorView = {
    return UIActivityIndicatorView(frame: self.photoImageView.frame).then {
      $0.activityIndicatorViewStyle = .White
      $0.autoresizingMask = .FlexibleWidth
    }
  }()
  private lazy var placeholderLabel: UILabel = {
    return UILabel(frame: self.photoImageView.frame).then {
      $0.optimize()
      $0.backgroundColor = UIColor.whiteColor().alpha(0.2)
      $0.textColor = .whiteColor()
      $0.textAlignment = .Center
      $0.font = .lightFontOfSize(42)
      $0.hidden = true
    }
  }()
  private lazy var nameLabel: MovieInfoLabel = {
    return MovieInfoLabel(frame: CGRect(x: 5, y: self.height - 45, width: self.width - 10, height: 45)).then {
      $0.textColor = .whiteColor()
      $0.textAlignment = .Center
      $0.font = .regularFontOfSize(14)
      $0.numberOfLines = 2
      $0.adjustsFontSizeToFitWidth = true
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    [photoImageView, activityIndicatorView, placeholderLabel, nameLabel].forEach { contentView.addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionReusableView

  override func prepareForReuse() {
    photoImageView.image = nil
    placeholderLabel.hidden = true
    nameLabel.text = nil
  }

  // MARK: Public methods

  func configure(actor: MovieCrewMember, photo: Photo?) {
    nameLabel.text = actor.name

    guard let photo = photo else {
      placeholderLabel.text = actor.nameInitials
      placeholderLabel.hidden = false
      return
    }

    if photo.image == nil {
      activityIndicatorView.startAnimating()
    }

    photo.getImage
      .driveNext { image in
        self.activityIndicatorView.stopAnimating()
        if let image = image {
          self.photoImageView.image = image
        } else {
          self.placeholderLabel.text = actor.nameInitials
          self.placeholderLabel.hidden = false
        }
      }
      .addDisposableTo(rx_disposeBag)
  }
}
