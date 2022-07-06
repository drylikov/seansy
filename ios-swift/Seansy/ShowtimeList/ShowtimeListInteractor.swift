import RxSwift

typealias ShowtimeListUpdate = [Movie]

protocol ShowtimeListInteractor: MovieDetailsRouteInteractor {
  var showtimeUpdates: Observable<ShowtimeListUpdate> { get }
  var updateShowtimes: Observable<Showtimes> { get }
  func startLoading()
}

extension DataManager: ShowtimeListInteractor {
  var showtimeUpdates: Observable<ShowtimeListUpdate> {
    let observable = dataUpdates
      .filter { _, _, _, change in change != .Cinemas }
      .map { movies, _, _, _ in movies[.NowPlaying] ?? [] }

    return formattedData.movies.flatMap { observable.startWith($0[.NowPlaying] ?? []) } ?? observable
  }
}
