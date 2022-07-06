import MYNStickyFlowLayout
import Reusable
import RxDataSources
import Sugar
import UIKit

struct MovieListSection {

  // MARK: Inputs

  var movies: [Movie]
  let date: NSDate?

  // MARK: Initialization

  init(movies: [Movie], date: NSDate? = nil) {
    self.movies = movies
    self.date = date
  }
}

extension MovieListSection: AnimatableSectionModelType {
  typealias Item = Movie
  typealias Identity = String

  // MARK: AnimatableSectionModelType

  var identity: String { return date?.shortReleaseDateString ?? "Сегодня в кино" }
  var items: [Item] { return movies }

  init(original: MovieListSection, items: [Item]) {
    self = original
    movies = items
  }
}

// MARK: -

final class MovieListPosterCell: MovieSummaryCollectionViewCell {
  override func factoryForBounds(bounds: CGRect) -> MovieSummaryViewFactory {
    return MoviePosterSummaryViewFactory(bounds: bounds)
  }
}

// MARK: -

final class MovieListView: UICollectionView {
  init(type: MovieType) {
    let flowLayout = (type == .NowPlaying ? UICollectionViewFlowLayout() : MYNStickyFlowLayout()).then {
      $0.scrollDirection = .Vertical
      $0.minimumInteritemSpacing = 0
      $0.minimumLineSpacing = 0

      let columns = screenWidth <= 414 ? 3 : 4
      let width = screenWidth / CGFloat(columns)
      let height = width / 0.7
      $0.itemSize = CGSize(width: width, height: height)

      $0.headerReferenceSize = CGSize(
        width: screenWidth,
        height: type == .NowPlaying ? MovieSummaryViewFactory.height : ListSectionHeaderView.height
      )
    }
    super.init(frame: .zero, collectionViewLayout: flowLayout)

    optimize()
    backgroundColor = .clearColor()
    indicatorStyle = .White
    registerReusableCell(MovieListPosterCell)
    switch type {
    case .NowPlaying:
      registerReusableSupplementaryView(
        UICollectionElementKindSectionHeader,
        viewType: MovieListCarouselHeaderView.self
      )
    case .ComingSoon:
      registerReusableSupplementaryView(
        UICollectionElementKindSectionHeader,
        viewType: MovieListDateSectionHeaderView.self
      )
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
