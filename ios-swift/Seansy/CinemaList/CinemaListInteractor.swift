import RxSwift

protocol CinemaListInteractor {
  var cinemaUpdates: Observable<Cinemas> { get }
  func startLoading()
}

extension DataManager: CinemaListInteractor {
  var cinemaUpdates: Observable<Cinemas> {
    let observable = dataUpdates
      .filter { _, _, _, change in change != .Movies }
      .map { _, cinemas, _, _ in cinemas }

    return formattedData.cinemas.flatMap { observable.startWith($0) } ?? observable
  }
}
