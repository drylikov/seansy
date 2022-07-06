import NSObject_Rx
import RxSwift
import UIKit

final class CinemaListViewController: TabBarItemViewController {

  // MARK: TabBarItemViewController

  override var scrollView: UIScrollView { return listView }

  // MARK: Public properties

  let listView = CinemaSummaryListView()

  // MARK: Private properties

  private var moviesCustomization: MoviesCustomization!

  // MARK: Initialization

  required init(interactor: SearchRouteInteractor) {
    super.init(interactor: interactor)

    tabBarItem.title = "Кинотеатры"
    tabBarItem.image = UIImage(.CinemasIconOutline)
    tabBarItem.selectedImage = UIImage(.CinemasIconFill)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    moviesCustomization = MoviesCustomization(navigationController: navigationController!, interactor: interactor)
    navigationItemCoordinator.buttonItems.onNext([.Date, moviesCustomization.barButtonItem])
    navigationItemCoordinator.searchPlaceholder.value = interactor.selectedCity
      .flatMap { "Кинотеатры в \($0)" } ?? "Кинотеатры"

    interactor.selectedCityUpdates
      .map { "Кинотеатры в \($0)" }
      .bindTo(navigationItemCoordinator.searchPlaceholder)
      .addDisposableTo(rx_disposeBag)

    presenter.startLoading()
  }
}
