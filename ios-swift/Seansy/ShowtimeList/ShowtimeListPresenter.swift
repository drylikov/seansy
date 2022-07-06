import AMPopTip
import NSObject_Rx
import RxDataSources
import RxSwift
import Sugar
import Tactile
import UIKit

final class ShowtimeListPresenter: NSObject, Presenter {

  // MARK: Inputs

  let viewController: ShowtimeListViewController
  let interactor: ShowtimeListInteractor

  // MARK: Public properties

  var visiblePopTip: AMPopTip?

  // MARK: Private properties

  private var listView: MovieSummaryListView { return viewController.listView }
  private var refreshControl: UIRefreshControl { return viewController.refreshControl }
  private let movieListDataSource = RxTableViewSectionedAnimatedDataSource<MovieSummaryListSection>()

  // MARK: Initialization

  init(viewController: ShowtimeListViewController, interactor: ShowtimeListInteractor) {
    self.viewController = viewController
    self.interactor = interactor
    super.init()

    refreshControl.on(.ValueChanged) {
      self.interactor.updateShowtimes
        .subscribe(onDisposed: $0.endRefreshing)
        .addDisposableTo(self.rx_disposeBag)
    }

    listView.delegate = self
    listView.tap { gestureRecognizer in
      if self.listView.indexPathForRowAtPoint(gestureRecognizer.locationInView(self.listView)) != nil {
        gestureRecognizer.cancelsTouchesInView = false
      } else {
        gestureRecognizer.cancelsTouchesInView = self.visiblePopTip != nil
        self.hideVisiblePopTip()
      }
    }
    setUpDataSource()
  }

  // MARK: Presenter

  private(set) weak var gateTransitionView: UIView?
  private(set) var hasContent = false

  func startLoading() {
    viewController.startLoading()
    interactor.showtimeUpdates
      .debounce(0.3, scheduler: MainScheduler.instance)
      .map { movies in
        self.hasContent = !movies.isEmpty
        return [MovieSummaryListSection(movies: movies, title: "По фильму")]
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

  // MARK: Public methods

  func hideVisiblePopTip() {
    if let visiblePopTip = visiblePopTip {
      if !visiblePopTip.isAnimating { visiblePopTip.hide() }
    }
  }

  // MARK: Private methods

  private func setUpDataSource() {
    movieListDataSource.configureCell = { _, tableView, indexPath, movie in
      return tableView
        .dequeueReusableCell(indexPath: indexPath, cellType: MovieSummaryListCell.self)
        .then { $0.configure(movie, interactor: self.interactor) }
    }
  }
}

// MARK: - UITableViewDelegate

extension ShowtimeListPresenter: UITableViewDelegate {
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    gateTransitionView = tableView.cellForRowAtIndexPath(indexPath)
    let movie = movieListDataSource.itemAtIndexPath(indexPath)
    viewController.pushMovieDetails(movie, interactor: interactor, animated: true)

    tableView.deselectRowAtIndexPath(indexPath, animated: false)
  }
}
