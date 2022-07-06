import UIKit

typealias SearchRouteInteractor = protocol<
  SearchInteractor, MoviesCustomizationInteractor, SelectedDateInteractor, SelectedCityInteractor,
  ReachabilityInteractor
>

extension SearchViewController {
  static func new(placeholder: String?, interactor: SearchRouteInteractor) -> SearchViewController {
    return SearchViewController(placeholder: placeholder)
      .then { $0.presenter = SearchPresenter(viewController: $0, interactor: interactor) }
  }
}

// MARK: -

extension UIViewController {
  func pushSearch(placeholder: String?, interactor: SearchRouteInteractor, animated: Bool) {
    if let navigationController = self as? UINavigationController ?? navigationController {
      navigationController
        .pushViewController(SearchViewController.new(placeholder, interactor: interactor), animated: animated)
    }
  }
}
