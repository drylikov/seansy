import NSObject_Rx
import RxDataSources
import RxSwift
import Tactile
import UIKit

final class MovieListPresenter: NSObject, Presenter {

  // MARK: Inputs

  let viewController: MovieListChildViewController
  let interactor: MovieListInteractor

  // MARK: Private properties

  private var type: MovieType { return viewController.type }
  private var listView: MovieListView { return viewController.listView }
  private var refreshControl: UIRefreshControl { return viewController.refreshControl }
  private let movieListDataSource = RxCollectionViewSectionedAnimatedDataSource<MovieListSection>()

  // MARK: Initialization

  init(viewController: MovieListChildViewController, interactor: MovieListInteractor) {
    self.viewController = viewController
    self.interactor = interactor
    super.init()

    refreshControl.on(.ValueChanged) {
      self.interactor.updateMovies
        .subscribe(onDisposed: $0.endRefreshing)
        .addDisposableTo(self.rx_disposeBag)
    }

    listView.delegate = self
    setUpDataSource()
  }

  // MARK: Presenter

  private(set) weak var zoomTransitionView: UIView?
  private(set) weak var gateTransitionView: UIView?
  private(set) var hasContent = false

  func startLoading() {
    viewController.startLoading()
    interactor.movieUpdates
      .debounce(0.3, scheduler: MainScheduler.instance)
      .map { nowPlayingMovies, comingSoonMovies -> [MovieListSection] in
        switch self.type {
        case .NowPlaying:
          self.hasContent = !nowPlayingMovies.isEmpty
          return self.hasContent ? [MovieListSection(movies: nowPlayingMovies)] : []
        case .ComingSoon:
          self.hasContent = !comingSoonMovies.isEmpty
          return comingSoonMovies
            .map { MovieListSection(movies: $1, date: $0) }
            .sort { $0.date ?? NSDate() < $1.date ?? NSDate() }
        }
      }
      .doOnError { self.viewController.endLoading(error: $0) }
      .doOnNext { _ in self.viewController.endLoading() }
      .bindTo(listView.rx_itemsAnimatedWithDataSource(movieListDataSource))
      .addDisposableTo(rx_disposeBag)
  }

  func retryLoading() {
    viewController.startLoading()
    interactor.startLoading()
  }

  // MARK: Private methods

  private func setUpDataSource() {
    movieListDataSource.cellFactory = { _, collectionView, indexPath, movie in
      return collectionView
        .dequeueReusableCell(indexPath: indexPath, cellType: MovieListPosterCell.self)
        .then { $0.configure(movie) }
    }
    movieListDataSource.supplementaryViewFactory = { dataSource, collectionView, _, indexPath in
      switch self.type {
      case .NowPlaying:
        return collectionView
          .dequeueReusableSupplementaryView(
            UICollectionElementKindSectionHeader,
            indexPath: indexPath,
            viewType: MovieListCarouselHeaderView.self
          )
          .then {
            guard let featuredMovies = self.interactor.featuredMovies else { return }

            $0.interactor = self.interactor
            $0.items = featuredMovies.map { movie in
              MovieListCarouselHeaderViewItem(movie: movie, handler: { view in
                self.zoomTransitionView = nil
                self.gateTransitionView = view
                self.viewController.pushMovieDetails(movie, interactor: self.interactor, animated: true)
              })
            }
        }
      case .ComingSoon:
        return collectionView
          .dequeueReusableSupplementaryView(
            UICollectionElementKindSectionHeader,
            indexPath: indexPath,
            viewType: MovieListDateSectionHeaderView.self
          )
          .then { $0.configure(dataSource.sectionAtIndex(indexPath.section).identity) }
      }
    }
  }
}

// MARK: - UICollectionViewDelegate

extension MovieListPresenter: UICollectionViewDelegate {
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    gateTransitionView = nil
    zoomTransitionView = collectionView.cellForItemAtIndexPath(indexPath)

    let movie = movieListDataSource.itemAtIndexPath(indexPath)
    viewController.pushMovieDetails(movie, interactor: interactor, animated: true)
  }
}
