import Foundation
import RxSwift
import SwiftDate

enum MovieType: String {
  case NowPlaying = "Сегодня в кино"
  case ComingSoon = "Скоро на экранах"
}

typealias MovieId = String
typealias CinemaId = String
typealias Showtimes = [MovieId: [CinemaId: [Showtime]]]
typealias Movies = [MovieType: [Movie]]
typealias Cinemas = [Cinema]
typealias DataUpdate = (Movies, Cinemas, Showtimes, DataUpdateChange)

enum DataUpdateChange: String {
  case Movies = "Movies", Cinemas = "Cinemas", Showtimes = "Showtimes"
}

struct FormattedData {

  // MARK: Inputs

  let updateSubject: PublishSubject<DataUpdate>

  // MARK: Public properties

  var movies: Movies? { return _movies.formatted }
  var cinemas: Cinemas? { return _cinemas.formatted }
  var showtimes: Showtimes? { return _showtimes.formatted }
  var movieFilters: MovieFilters? { return _movies.filters }
  var moviesSortBy: MoviesSortBy {
    get { return _movies.sortBy }
    set { _movies.sortBy = newValue; update(.Movies) }
  }
  var cinemasSortBy: CinemasSortBy {
    get { return _cinemas.sortBy }
    set { _cinemas.sortBy = newValue; update(.Cinemas) }
  }
  var date: NSDate {
    get { return _showtimes.date }
    set { _showtimes.date = newValue; update(.Showtimes) }
  }

  // MARK: Private properties

  private var _movies = MovieList()
  private var _cinemas = CinemaList()
  private var _showtimes = ShowtimeList()

  // MARK: Initialization

  init(updateSubject: PublishSubject<DataUpdate>) {
    self.updateSubject = updateSubject
  }

  // MARK: Public methods

  mutating func setMovies(movies: [Movie]?) -> Movies {
    _movies.original = movies
    update(.Movies)
    return self.movies ?? [:]
  }

  mutating func setCinemas(cinemas: [Cinema]?) -> Cinemas {
    _cinemas.original = cinemas
    update(.Cinemas)
    return self.cinemas ?? []
  }

  mutating func setShowtimes(showtimes: [Showtime]?) -> Showtimes {
    _showtimes.original = showtimes
    _movies.showtimes = _showtimes.byMovie
    _cinemas.showtimes = _showtimes.byCinema
    update(.Showtimes)
    return self.showtimes ?? [:]
  }

  mutating func refreshMovies() {
    _movies.refresh()
    update(.Movies)
  }
  mutating func refreshCinema() {
    _cinemas.refresh()
    update(.Cinemas)
  }

  // MARK: Private methods

  func update(change: DataUpdateChange) {
    log.info("📤 \(change) update published")
    updateSubject.onNext((movies ?? [:], cinemas ?? [], showtimes ?? [:], change))
  }
}

// MARK: -

private struct MovieList {

  // MARK: Public properties

  var original: [Movie]? {
    didSet {
      filters = original.flatMap { MovieFilters(movies: $0.filter { $0.releaseDate == nil }) }
      refresh()
    }
  }
  var showtimes: [MovieId: [Showtime]]? {
    didSet { refresh() }
  }
  var sortBy = Cache[.moviesSortBy].flatMap({ MoviesSortBy(rawValue: $0) }) ?? .Popularity {
    didSet {
      Cache[.moviesSortBy] = sortBy.rawValue
      formatted = formatted?.map { type, movies in
        switch type {
        case .NowPlaying: return movies.sorted(self.sortBy, showtimes: self.showtimes)
        case .ComingSoon: return movies
        }
      }
    }
  }
  private(set) var filters: MovieFilters?
  var formatted: Movies?

  // MARK: Public methods

  mutating func refresh() {
    formatted = original?
      .groupedBy { return $0.releaseDate == nil ? MovieType.NowPlaying : MovieType.ComingSoon }
      .map { type, movies in
        switch type {
        case .NowPlaying:
          return movies
            .filtered(self.filters, showtimes: self.showtimes)
            .sorted(self.sortBy, showtimes: self.showtimes)
        case .ComingSoon:
          return movies.sorted(.Title)
        }
    }
  }
}

// MARK: -

private struct CinemaList {

  // MARK: Public properties

  var original: [Cinema]? {
    didSet { refresh() }
  }
  var showtimes: [CinemaId: [Showtime]]? {
    didSet { refresh() }
  }
  var sortBy = Cache[.cinemasSortBy].flatMap({ CinemasSortBy(rawValue: $0) })  ?? .ShowtimesCount {
    didSet {
      Cache[.cinemasSortBy] = sortBy.rawValue
      refresh()
    }
  }
  var formatted: [Cinema]?

  // mARK: Public methods

  mutating func refresh() {
    formatted = original?.sorted(sortBy, showtimes: showtimes)
  }
}

private struct ShowtimeList {

  // MARK: Public properties

  var original: [Showtime]? {
    didSet { refresh() }
  }
  var date = today {
    didSet { refresh() }
  }
  var byMovie: [MovieId: [Showtime]]?
  var byCinema: [CinemaId: [Showtime]]?
  var formatted: Showtimes?

  // MARK: Public methods

  mutating func refresh() {
    let iso8601Date = iso8601Formatter.stringFromDate(date)
    let showtimes = original?.filter { iso8601Formatter.stringFromDate($0.time) == iso8601Date }
    byMovie = showtimes?.groupedBy { $0.movieId }
    byCinema = showtimes?.groupedBy { $0.cinemaId }
    formatted = byMovie?.map { $1.groupedBy { $0.cinemaId } }
  }
}
