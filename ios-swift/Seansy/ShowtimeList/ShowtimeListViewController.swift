import NSObject_Rx
import RxSwift
import Tactile
import UIKit

final class ShowtimeListViewController: TabBarItemViewController {

  // MARK: TabBarItemViewController

  override var scrollView: UIScrollView { return listView }

  // MARK: Public properties

  private(set) lazy var listView: MovieSummaryListView = {
    return MovieSummaryListView().then {
      $0.alwaysBounceVertical = true
      $0.addSubview(self.refreshControl)
      $0.sendSubviewToBack(self.refreshControl)
    }
  }()
  let refreshControl = UIRefreshControl().then { $0.tintColor = .whiteColor() }

  // MARK: Private properties

  private var moviesCustomization: MoviesCustomization!

  // MARK: Initialization

  required init(interactor: SearchRouteInteractor) {
    super.init(interactor: interactor)

    tabBarItem.title = "Сеансы"
    tabBarItem.image = UIImage(.ShowtimesIconOutline)
    tabBarItem.selectedImage = UIImage(.ShowtimesIconFill)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    moviesCustomization = MoviesCustomization(navigationController: navigationController!, interactor: interactor)
    navigationItemCoordinator.buttonItems.onNext([.Date, moviesCustomization.barButtonItem])
    navigationItemCoordinator.searchPlaceholder.value = "Сеансы \(interactor.selectedDate.shortDateMenuString)"

    interactor.selectedDateUpdates
      .map { "Сеансы \($0.shortDateMenuString)" }
      .bindTo(navigationItemCoordinator.searchPlaceholder)
      .addDisposableTo(rx_disposeBag)

    presenter.startLoading()
  }
}
