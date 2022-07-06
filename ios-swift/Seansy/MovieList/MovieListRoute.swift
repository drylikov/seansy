import UIKit

typealias MovieListRouteInteractor = protocol<MovieListInteractor, SearchRouteInteractor>

final class MovieListRoute: Route {

  // MARK: Routable

  override func resolve(arguments: [String: String], navigationController: UINavigationController?) {
    guard let type = arguments["type"].flatMap({ $0.stringByRemovingPercentEncoding }),
      movieListVC = navigationController?.visibleViewController as? MovieListViewController else { return }

    switch type {
    case "now-playing":
      if movieListVC.currentIndex != 0 { movieListVC.moveToViewControllerAtIndex(0) }
    case "coming-soon":
      if movieListVC.currentIndex != 1 { movieListVC.moveToViewControllerAtIndex(1) }
    default: break
    }
  }
}

// MARK: -

extension MovieListViewController {
  static func new(interactor: MovieListRouteInteractor) -> MovieListViewController {
    return MovieListViewController(
      childVCs: [.NowPlaying, .ComingSoon].map {
        MovieListChildViewController(type: $0)
          .then { $0.presenter = MovieListPresenter(viewController: $0, interactor: interactor) }
      },
      interactor: interactor
    )
  }
}

// MARK: -

extension UIViewController {
  func pushMovieList(interactor: MovieListRouteInteractor, animated: Bool) {
    if let navigationController = self as? UINavigationController ?? navigationController {
      navigationController.pushViewController(MovieListViewController.new(interactor), animated: animated)
    }
  }
}
