import Sugar
import UIKit

private final class MovieRatingView: UIView {

  // MARK: Inputs

  let rating: MovieRating

  // MARK: Private properties

  private lazy var ratingImageView: UIImageView = {
    return UIImageView(image: self.rating.asset.flatMap { UIImage($0) }).then {
      $0.optimize()
      $0.frame = CGRect(
        width: $0.image!.size.width / $0.image!.size.height * self.height,
        height: self.height
      )
    }
  }()
  private lazy var ratingLabel: UILabel = {
    return UILabel(frame: CGRect(x: self.ratingImageView.right + 6, y: 0, width: 0, height: self.height)).then {
      $0.optimize()
      $0.textColor = .whiteColor()
      $0.attributedText = self.rating.attributedString
      $0.sizeToFit()
      $0.centerY = self.height / 2
    }
  }()

  // MARK: Initialization

  init(frame: CGRect, rating: MovieRating) {
    self.rating = rating
    super.init(frame: frame)

    [ratingImageView, ratingLabel].forEach { addSubview($0) }
    width = ratingLabel.right
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

final class MovieRatingsView: UIScrollView {
  init(frame: CGRect, ratings: MovieRatings) {
    super.init(frame: frame)

    optimize()
    showsHorizontalScrollIndicator = false

    contentInset.left = 10
    contentSize.width = [.Kinopoisk, .IMDB, .RTCritics, .RTAudience].map { ratings[$0] }.flatMap { $0 }
      .map { MovieRatingView(frame: heightLens.to(frame.height, .zero), rating: $0) }
      .reduce(CGFloat(0.0)) { offset, ratingView in
        ratingView.left = offset > 0 ? offset + 10 : offset
        addSubview(ratingView)

        return ratingView.right
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
