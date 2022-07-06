import Kingfisher
import Sugar
import UIKit

final class MoviePosterSummaryViewFactory: MovieSummaryViewFactory {

  // Initialization

  override init(bounds: CGRect) {
    super.init(bounds: bounds)

    imageView.gradientType = .Poster
    ratingStarsView.frame = CGRect(x: bounds.width * 0.1, y: bounds.height - 25, width: bounds.width * 0.8, height: 20)
    ratingStarsView.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
    ratingLabel.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
  }

  // MARK: SummaryViewFactory

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.gradientView.hidden = true
  }

  // MARK: MovieSummaryViewFactory

  override func setInfoAlpha(alpha: CGFloat) {
    super.setInfoAlpha(alpha)
    imageView.gradientView.alpha = alpha
  }

  override func configure(movie: Movie) {
    super.configure(movie)

    if movie.releaseDate == nil && movie.averageRating > 0 { imageView.gradientView.hidden = false }
    if let posterUrl = movie.posterUrl {
      let imageCached = ImageCache.defaultCache.cachedImageExistsforURL(posterUrl)
      imageView.kf_setImageWithURL(
        posterUrl,
        placeholderImage: imageCached ? nil : UIImage(.PosterPlaceholder),
        optionsInfo: [.Transition(ImageTransition.Fade(0.3))]
      )
    } else {
      imageView.image = UIImage(.PosterPlaceholder)
    }
  }
}
