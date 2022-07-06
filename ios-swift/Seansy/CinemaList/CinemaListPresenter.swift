import NSObject_Rx
import RxDataSources
import RxSwift
import Sugar
import UIKit

final class CinemaListPresenter: NSObject, Presenter {

  // MARK: Inputs

  let viewController: CinemaListViewController
  let interactor: CinemaListInteractor

  // MARK: Private properties

  private var listView: CinemaSummaryListView { return viewController.listView }
  private let cinemaListDataSource = RxTableViewSectionedAnimatedDataSource<CinemaSummaryListSection>()

  // MARK: Initialization

  init(viewController: CinemaListViewController, interactor: CinemaListInteractor) {
    self.viewController = viewController
    self.interactor = interactor
    super.init()

//    listView.delegate = self
    setUpDataSource()
  }

  // MARK: Presenter

  private(set) weak var gateTransitionView: UIView?
  private(set) var hasContent = false

  func startLoading() {
    viewController.startLoading()
    interactor.cinemaUpdates
      .debounce(0.3, scheduler: MainScheduler.instance)
      .map { cinemas in
        self.hasContent = !cinemas.isEmpty
        return self.hasContent ? [CinemaSummaryListSection(cinemas: cinemas, title: "Кинотеатры")] : []
      }
      .doOnError { self.viewController.endLoading(error: $0) }
      .doOnNext { _ in self.viewController.endLoading() }
      .bindTo(listView.rx_itemsAnimatedWithDataSource(cinemaListDataSource))
      .addDisposableTo(rx_disposeBag)
  }

  func retryLoading() {
    viewController.startLoading()
    interactor.startLoading()
  }

  // MARK: Private methods

  private func setUpDataSource() {
    cinemaListDataSource.configureCell = { _, tableView, indexPath, cinema in
      return tableView
        .dequeueReusableCell(indexPath: indexPath, cellType: CinemaSummaryListCell.self)
        .then { $0.configure(cinema) }
    }
  }
}
