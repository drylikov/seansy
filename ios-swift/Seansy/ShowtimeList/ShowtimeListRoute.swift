typealias ShowtimeListRouteInteractor = protocol<ShowtimeListInteractor, SearchRouteInteractor>

extension ShowtimeListViewController {
  static func new(interactor: ShowtimeListRouteInteractor) -> ShowtimeListViewController {
    return ShowtimeListViewController(interactor: interactor)
      .then { $0.presenter = ShowtimeListPresenter(viewController: $0, interactor: interactor) }
  }
}
