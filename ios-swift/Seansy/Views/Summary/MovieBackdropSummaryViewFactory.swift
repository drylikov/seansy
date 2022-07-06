import Kingfisher
import NSObject_Rx
import RxCocoa
import RxSwift
import Sugar
import UIKit

private final class MovieGenreLabel: UILabel {
  init(genre: String) {
    super.init(frame: .zero)

    optimize()
    backgroundColor = UIColor.blackColor().alpha(0.25)
    textColor = BackdropColors.defaultTextColor
    textAlignment = .Center
    font = .regularFontOfSize(12)
    text = genre.uppercaseString
    sizeToFit()
    width += 16
    height += 4
    layer.cornerRadius = height / 2
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

final class MovieGenresView: UIView {
  var genres = [String]() {
    didSet {
      labels.forEach { $0.removeFromSuperview() }
      labels = []

      let newLabels = genres.map { MovieGenreLabel(genre: $0) }
      var left: CGFloat = 0
      for label in newLabels {
        if left + label.width >= frame.width { break }

        labels.append(label)
        addSubview(label)
        label.left = left
        left = label.right + 4
      }
      height = labels.map { $0.height }.maxElement() ?? 0
    }
  }

  private var labels = [MovieGenreLabel]()
}

// MARK: -

final class MovieBackdropSummaryViewFactory: MovieSummaryViewFactory {

  // Views
  private(set) lazy var titleLabel: UILabel = {
    return UILabel().then {
      $0.autoresizingMask = .FlexibleTopMargin
      $0.textColor = .whiteColor()
      $0.font = .lightFontOfSize(22)
      $0.hidden = true
    }
  }()
  private(set) lazy var genresView: MovieGenresView = {
    return MovieGenresView(frame: CGRect(x: 10, y: 10, width: self.bounds.width - 20, height: 0))
  }()

  // MARK: Initialization

  override init(bounds: CGRect) {
    super.init(bounds: bounds)

    imageView.contentMode = .ScaleAspectFill
    imageView.alpha = 0.75
    imageView.gradientView.hidden = false
    titleLabel.frame = CGRect(x: 10, y: 0, width: bounds.width - 20, height: 0)
    ratingStarsView.frame = CGRect(x: 10, y: bounds.height - 30, width: 100, height: 20)
    ratingStarsView.autoresizingMask = .FlexibleTopMargin
    ratingLabel.autoresizingMask = .FlexibleTopMargin
  }

  // MARK: SummaryViewFactory

  override var subviews: [UIView] { return super.subviews + [titleLabel, genresView] }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.gradientType = nil
    titleLabel.hidden = true
    titleLabel.text = nil
    genresView.genres = []
  }

  // MARK: MovieSummaryViewFactory

  override func setInfoAlpha(alpha: CGFloat) {
    super.setInfoAlpha(alpha)
    titleLabel.alpha = alpha
    genresView.alpha = alpha
  }

  // MARK: Public methods

  func configure(movie movie: Movie, interactor: BackdropColorsInteractor?) {
    super.configure(movie)

    titleLabel.hidden = false
    titleLabel.text = movie.title
    titleLabel.adjustFontSize(2, minSize: 18)
    if !ratingLabel.hidden {
      titleLabel.bottom = ratingStarsView.top - 5
    } else if !ratingStarsView.hidden {
      titleLabel.bottom = ratingStarsView.top - 5
    } else {
      titleLabel.bottom = bounds.height - 10
    }
    genresView.genres = movie.genres ?? []

    if let imageUrl = movie.backdropUrl ?? movie.posterUrl {
      imageView.kf_setImageWithURL(
        imageUrl,
        placeholderImage: nil,
        optionsInfo: [.Transition(ImageTransition.Fade(0.3))]) { image, error, _, _ in
          guard let image = image else {
            self.imageView.image = UIImage(.MovieBackdropPlaceholder)
            return
          }

          if let colors = interactor?.backdropColors[imageUrl] {
            self.imageView.gradientType = .Backdrop(colors[.Background])
          } else {
            BackdropColors.getColors(image)
              .doOnNext { interactor?.setBackdropColors($0, url: imageUrl) }
              .driveNext { self.imageView.gradientType = .Backdrop($0[.Background]) }
              .addDisposableTo(self.rx_disposeBag)
          }
      }
    } else {
      imageView.image = UIImage(.MovieBackdropPlaceholder)
    }
  }

  func configure(imageUrl imageUrl: NSURL) {
    imageView.kf_setImageWithURL(imageUrl, placeholderImage: nil, optionsInfo: [.Transition(ImageTransition.Fade(0.3))])
  }
}
