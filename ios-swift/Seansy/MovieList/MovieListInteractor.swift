import Foundation
import RxSwift

typealias MovieListUpdate = ([Movie], [NSDate: [Movie]])

protocol MovieListInteractor: MovieDetailsRouteInteractor {
  var movieUpdates: Observable<MovieListUpdate> { get }
  var updateMovies: Observable<Movies> { get }
  var featuredMovies: [Movie]? { get }
  func startLoading()
}

extension DataManager: MovieListInteractor {
  var movieUpdates: Observable<MovieListUpdate> {
    let observable = dataUpdates
      .filter { _, _, _, change in change != .Cinemas }
      .map { movies, _, _, _ in (movies[.NowPlaying] ?? [], (movies[.ComingSoon] ?? []).groupedByDate) }

    return formattedData.movies
      .flatMap { observable.startWith(($0[.NowPlaying] ?? [], ($0[.ComingSoon] ?? []).groupedByDate)) } ?? observable
  }

  var featuredMovies: [Movie]? {
    return rawData.movies.flatMap {
      let movies = $0.filter { $0.releaseDate == nil && $0.backdropUrl != nil }
      return movies.count >= 5 ? Array(movies.sorted(.Popularity)[0..<5]) : nil
    }
  }
}
