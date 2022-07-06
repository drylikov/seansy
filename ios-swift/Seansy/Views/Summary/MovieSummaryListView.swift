import Reusable
import RxDataSources
import Sugar
import UIKit

struct MovieSummaryListSection {
  var movies: [Movie]
  let title: String
}

extension MovieSummaryListSection: AnimatableSectionModelType {
  typealias Item = Movie
  typealias Identity = String

  var identity: String { return title }
  var items: [Item] { return movies }

  init(original: MovieSummaryListSection, items: [Item]) {
    self = original
    movies = items
  }
}

// MARK: -

final class MovieSummaryListCell: UITableViewCell, Reusable, Transitionable {

  // MARK: Private properties

  private var factory: MovieBackdropSummaryViewFactory!

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    size = CGSize(width: screenWidth, height: MovieSummaryViewFactory.height)
    factory = MovieBackdropSummaryViewFactory(bounds: sizeLens.to(size, .zero))

    optimize()
    backgroundColor = .blackColor()
    backgroundView = factory.imageView
    selectionStyle = .None
    factory.subviews.forEach { addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewCell

  override func prepareForReuse() { factory.prepareForReuse() }

  // MARK: Transitionable

  func setInfoAlpha(alpha: CGFloat) { factory.setInfoAlpha(alpha) }

  // MARK: Public methods

  func configure(movie: Movie, interactor: BackdropColorsInteractor?) {
    factory.configure(movie: movie, interactor: interactor)
  }
}

// MARK: -

final class MovieSummaryListView: SummaryListView {
  override init() {
    super.init()

    rowHeight = MovieSummaryViewFactory.height
    registerReusableCell(MovieSummaryListCell)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
