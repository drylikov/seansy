import NSObject_Rx
import RxSwift
import UIKit

typealias MovieDetailsRouteInteractor = BackdropColorsInteractor

final class MovieDetailsRoute: Route {

  // MARK: Public methods

  static func path(movie: Movie) -> String { return "movie:\(movie.id)" }

  // MARK: Routable

  override func resolve(arguments: [String: String], navigationController: UINavigationController?) {
    guard let id = arguments["id"].flatMap({ $0.stringByRemovingPercentEncoding }) else { return }

    dataManager.dataUpdates
      .filter { _, _, _, change in change != .Cinemas }
      .subscribeNext { movies, _, _, _ in
        if let movie = movies.values.reduce([], combine: +).find({ $0.id == id }) {
          navigationController?.pushMovieDetails(movie, interactor: self.dataManager, animated: true)
        } else {
          navigationController?.presentError(title: "Ошибка", subtitle: "К сожалению, такой фильм не найден.")
        }
      }
      .addDisposableTo(rx_disposeBag)
  }
}

// MARK: -

extension MovieDetailsViewController {
  static func new(movie: Movie, interactor: MovieDetailsRouteInteractor) -> MovieDetailsViewController {
    return MovieDetailsViewController(movie: movie, presenter: MovieDetailsPresenter(), interactor: interactor)
      .then { $0.presenter.viewController = $0 }
  }
}

// MARK: -

extension UIViewController {
  func pushMovieDetails(movie: Movie, interactor: MovieDetailsRouteInteractor, animated: Bool) {
    if let navigationController = self as? UINavigationController ?? navigationController {
      navigationController
        .pushViewController(MovieDetailsViewController.new(movie, interactor: interactor), animated: animated)
    }
  }
}
