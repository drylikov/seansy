import Foundation

final class MovieFilters {

  // MARK: Inputs

  let movies: [Movie]

  // MARK: Public properties

  var ratingFilter: Float! {
    didSet { Cache[.movieRatingFilter] = Double(ratingFilter) }
  }
  var runtimeFilter: Int! {
    didSet { Cache[.movieRuntimeFilter] = Int(runtimeFilter) }
  }
  var childrenFilter: Bool! {
    didSet { Cache[.movieChildrenFilter] = childrenFilter }
  }
  var genresFilter: [String]! {
    didSet { Cache[.movieGenresFilter] = genresFilter }
  }
  var combinedFilter: Movie -> Bool {
    return {
      if $0.releaseDate != nil { return true }

      if self.ratingFilter > self.minRating {
        if $0.averageRating < self.ratingFilter { return false }
      }
      if self.runtimeFilter < self.maxRuntime {
        if $0.runtime != nil && $0.runtime! > self.runtimeFilter { return false }
      }
      if let childrenFilter = self.childrenFilter {
        if childrenFilter {
          if $0.ageRating == nil || $0.ageRating! > 14 { return false }
        }
      }
      if !self.genresFilter.isEmpty {
        guard let genres = $0.genres else { return false }
        return !Set(genres).intersect(Set(self.genresFilter)).isEmpty
      }

      return true
    }
  }

  // Constants
  lazy var minRating: Float = {
    return self.movies.minRating ?? 0.0
  }()
  lazy var maxRating: Float = {
    return self.movies.maxRating ?? 100.0
  }()
  lazy var minRuntime: Int = {
    return self.movies.minRuntime ?? 0
  }()
  lazy var maxRuntime: Int = {
    return self.movies.maxRuntime ?? 360
  }()
  lazy var genres: [String] = {
    return self.movies.genres
  }()

  // MARK: Initialization

  init?(movies: [Movie]) {
    self.movies = movies

    if movies.isEmpty { return nil }

    if Cache[.persistMovieFilters] {
      ratingFilter = Cache[.movieRatingFilter].flatMap { Float($0) } ?? minRating
      if ratingFilter > maxRating {
        ratingFilter = maxRating
      }

      runtimeFilter = Cache[.movieRuntimeFilter] ?? maxRuntime
      if runtimeFilter < minRuntime {
        runtimeFilter = minRuntime
      }

      childrenFilter = Cache[.movieChildrenFilter]
      genresFilter = Cache[.movieGenresFilter]
    } else {
      ratingFilter = minRating
      runtimeFilter = maxRuntime
      childrenFilter = false
      genresFilter = []
    }
  }
}
