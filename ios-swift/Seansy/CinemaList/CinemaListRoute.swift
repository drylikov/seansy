typealias CinemaListRouteInteractor = protocol<CinemaListInteractor, SearchRouteInteractor>

extension CinemaListViewController {
  static func new(interactor: CinemaListRouteInteractor) -> CinemaListViewController {
    return CinemaListViewController(interactor: interactor)
      .then { $0.presenter = CinemaListPresenter(viewController: $0, interactor: interactor) }
  }
}
