import NSObject_Rx
import RxSwift
import UIKit
import XLPagerTabStrip

final class MovieListViewController: TabBarItemPagerViewController<MovieListChildViewController> {

  // MARK: Initialization

  required init(childVCs: [MovieListChildViewController], interactor: SearchRouteInteractor) {
    super.init(childVCs: childVCs, interactor: interactor)

    tabBarItem.title = "Фильмы"
    tabBarItem.image = UIImage(.MoviesIconOutline)
    tabBarItem.selectedImage = UIImage(.MoviesIconFill)
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    let moviesCustomization = MoviesCustomization(navigationController: navigationController!, interactor: interactor)

    rx_observe(Int.self, "currentIndex")
      .map { index -> String in
        switch self.childVCs[index!].type {
        case .NowPlaying: return "Фильмы \(self.interactor.selectedDate.shortDateMenuString)"
        case .ComingSoon: return "Ожидаемые фильмы"
        }
      }
      .bindTo(navigationItemCoordinator.searchPlaceholder)
      .addDisposableTo(rx_disposeBag)

    rx_observe(Int.self, "currentIndex")
      .map { index -> [NavigationBarButtonItem] in
        switch self.childVCs[index!].type {
        case .NowPlaying: return [.Date, moviesCustomization.barButtonItem]
        case .ComingSoon: return []
        }
      }
      .bindTo(navigationItemCoordinator.buttonItems)
      .addDisposableTo(rx_disposeBag)

    interactor.selectedDateUpdates
      .filter { _ in self.childVCs[self.currentIndex].type == .NowPlaying }
      .map { "Фильмы \($0.shortDateMenuString)" }
      .bindTo(navigationItemCoordinator.searchPlaceholder)
      .addDisposableTo(rx_disposeBag)
  }
}
