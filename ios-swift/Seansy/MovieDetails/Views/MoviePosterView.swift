import Kingfisher
import NYTPhotoViewer
import Sugar
import Tactile
import UIKit

final class MoviePosterView: UIView {

  // MARK: Private properties

  private lazy var imageView: UIImageView = {
    return UIImageView(frame: self.bounds).then {
      $0.optimize()
      $0.contentMode = .ScaleToFill
      $0.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    }
  }()

  // MARK: Initialization

  init(frame: CGRect, posterUrl: NSURL?, presenter: MovieDetailsPresenter) {
    super.init(frame: frame)

    addSubview(imageView)

    if let posterUrl = posterUrl {
      let imageCached = ImageCache.defaultCache.cachedImageExistsforURL(posterUrl)
      imageView.kf_setImageWithURL(posterUrl,
        placeholderImage: imageCached ? nil : UIImage(.PosterPlaceholder),
        optionsInfo: [.Transition(ImageTransition.Fade(0.3))]) { image, error, _, _ in
          guard let image = image else { return }

          self.userInteractionEnabled = true
          self.tap { _ in
            presenter.presentImages(NYTPhotosViewController(photos: [Poster(image: image)]).then { $0.delegate = self })
          }
      }
    } else {
      imageView.image = UIImage(.PosterPlaceholder)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - NYTPhotosViewControllerDelegate

extension MoviePosterView: NYTPhotosViewControllerDelegate {
  func photosViewController(photosViewController: NYTPhotosViewController, referenceViewForPhoto photo: NYTPhoto)
    -> UIView? { return self }

  func photosViewControllerDidDismiss(photosViewController: NYTPhotosViewController) {
    UIApplication.sharedApplication().statusBarHidden = false
  }
}
