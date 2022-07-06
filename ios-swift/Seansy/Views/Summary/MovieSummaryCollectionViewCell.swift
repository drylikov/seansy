import Reusable
import UIKit

class MovieSummaryCollectionViewCell: UICollectionViewCell, Reusable, Transitionable {

  // MARK: Public properties

  var factory: MovieSummaryViewFactory!

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    factory = factoryForBounds(bounds)

    optimize()
    backgroundColor = .blackColor()
    backgroundView = factory.imageView
    factory.subviews.forEach { addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionViewCell

  override func prepareForReuse() { factory.prepareForReuse() }

  // MARK: Transitionable

  func setInfoAlpha(alpha: CGFloat) { factory.setInfoAlpha(alpha) }

  // MARK: Public methods

  func factoryForBounds(bounds: CGRect) -> MovieSummaryViewFactory { return MovieSummaryViewFactory(bounds: bounds) }
  func configure(movie: Movie) { factory.configure(movie) }
}
