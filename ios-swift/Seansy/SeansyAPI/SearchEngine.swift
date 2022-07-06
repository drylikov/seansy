import Foundation
import PySwiftyRegex
import Sugar

typealias SearchIndex = [SearchItem]
typealias SearchDomain = (pattern: String, indices: [SearchIndex])
typealias SearchMatch = (score: Double, item: SearchItem)
typealias SearchResults = (movies: [Movie], cinemas: [Cinema], timeRange: TimeRange?)

final class SearchEngine {

  // MARK: Inputs

  let movies: [Movie]
  let cinemas: [Cinema]

  // MARK: Public properties

  var examples: [SearchItem] {
    let movieItems = nowPlayingMoviesIndex.sort { $0.query.length < $1.query.length }
    let cinemaItems = cinemasIndex.sort { $0.query.length < $1.query.length }

    var generatedExamples = [SearchItem]()

    if !movieItems.isEmpty && !cinemaItems.isEmpty {
      let randomMovieItems = movieItems.limit(5).shuffle().limit(2)
      let randomCinemaItems = cinemaItems.limit(5).shuffle().limit(2)
      let randomMovieFiltersItem = movieFiltersIndex.shuffle().first!
      let randomShowtimeFiltersItem = showtimeFiltersIndex.shuffle().first!

      generatedExamples += [
        SearchItem(components: randomMovieItems.first!.components + randomShowtimeFiltersItem.components),
        SearchItem(components: randomMovieItems.last!.components + randomCinemaItems.last!.components),
        randomMovieFiltersItem,
        randomCinemaItems.first!
      ]
    }

    return generatedExamples.shuffle()
  }

  // MARK: Private properties

  // Indices
  private lazy var moviesIndex: [MovieType: SearchIndex] = {
    return self.movies
      .groupedBy { $0.releaseDate == nil ? MovieType.NowPlaying : MovieType.ComingSoon }
      .map { _, movies in movies.map { SearchItem(movie: $0) } }
  }()
  private var nowPlayingMoviesIndex: SearchIndex { return moviesIndex[.NowPlaying] ?? [] }
  private var comingSoonMoviesIndex: SearchIndex { return moviesIndex[.ComingSoon] ?? [] }
  private lazy var cinemasIndex: SearchIndex = {
    return self.cinemas.map { SearchItem(cinema: $0) }
  }()
  private lazy var movieFiltersIndex: SearchIndex = {
    return (self.movies.genres + ["для детей"]).map { SearchItem(query: $0.uppercaseFirstChar(), type: .MovieFilters) }
  }()
  private lazy var showtimeFiltersIndex: SearchIndex = {
    var times: [String] = ["15 минут", "30 минут", "полчаса", "час"] +
      (1...12).map { $0.pluralize(["час", "часа", "часов"]) }
    times = times.map { ["на \($0)", "через \($0)"] }.flatten().flatMap { $0 }
    times += ["сегодня", "завтра", "утром", "днем", "вечером", "в обед", "после обеда", "после полудня"]
    return times.map { SearchItem(query: $0, type: .ShowtimeFilters) }
  }()

  // Search domains
  private lazy var moviesSearchDomain: SearchDomain = {
    return (pattern: "^(?:Фильмы?|Кино) (.+)",
      indices: [self.nowPlayingMoviesIndex, self.comingSoonMoviesIndex, self.movieFiltersIndex])
  }()
  private lazy var cinemasSearchDomain: SearchDomain = {
    return (pattern: "^Кинотеатры? (.+)", indices: [self.cinemasIndex])
  }()
  private lazy var showtimesSearchDomain: SearchDomain = {
    return (pattern: "^Сеансы? (.+)", indices: [self.showtimeFiltersIndex])
  }()

  // MARK: Private constants

  private let compoundCinemasPattern = " в\\s+(.+)$"
  private let compoundShowtimesPattern = " ((?:(?:на|через)\\s+(?:\\d+\\s+|минут|час)|(?:до|после|в|на)\\s+)?[^ ]*)$"

  // MARK: Initialization

  init(movies: [Movie], cinemas: [Cinema]) {
    self.movies = movies
    self.cinemas = cinemas
  }

  // MARK: Public methods

  func suggestionsForQuery(query: String) -> [SearchItem] {
    if query.isEmpty { return [] }

    let indices = [nowPlayingMoviesIndex, comingSoonMoviesIndex, cinemasIndex, movieFiltersIndex]
    var matches = findMatches(indices, query: query)
    [moviesSearchDomain, cinemasSearchDomain, showtimesSearchDomain].forEach { pattern, indices in
      if let filteredQuery = re.search(pattern, query)?.group(1)?.trim() {
        matches += findMatches(indices, query: filteredQuery)
      }
    }

    let showtimeMatches = compoundShowtimeMatches(query) ?? []
    matches += showtimeMatches
    if showtimeMatches.isEmpty {
      let cinemaMatches = compoundCinemaMatches(query) ?? []
      matches += cinemaMatches
    }

    return matches.sort { $0.score > $1.score }.map { $0.item }.unique.limit(5)
  }

  func resultsFromSuggestion(searchItem: SearchItem) -> SearchResults? {
    switch searchItem.type {
    case .MovieTitle:
      return movies.find { $0.title == searchItem.query }.flatMap { (movies: [$0], cinemas: [], timeRange: nil) }
    case .MovieFilters:
      let lowercaseQuery = searchItem.query.lowercaseString
      var movies: [Movie]
      if lowercaseQuery == "для детей" {
        movies = self.movies.filter { $0.ageRating != nil && $0.ageRating! <= 14 }
      } else {
        movies = self.movies.filter { $0.genres?.contains(lowercaseQuery) ?? false }
      }
      return (movies: movies, cinemas: [], timeRange: nil)
    case .CinemaName:
      return cinemas.find { $0.name == searchItem.query }.flatMap { (movies: [], cinemas: [$0], timeRange: nil) }
    default: return nil
    }
  }

  // MARK: Private methods

  private func compoundShowtimeMatches(query: String) -> [SearchMatch]? {
    if let compoundShowtimesPatternMatch = re.search(compoundShowtimesPattern, query),
      filteredQuery = compoundShowtimesPatternMatch.group().flatMap({ query.replace($0, with: "") }),
      compoundShowtimesQuery = compoundShowtimesPatternMatch.group(1)?.trim() {
        var originalMatches = compoundCinemaMatches(filteredQuery) ?? compoundCinemaMatches(query) ?? []
        if originalMatches.isEmpty {
          originalMatches = findMatches([nowPlayingMoviesIndex, movieFiltersIndex], query: filteredQuery)
        }
        let complementaryMatches = findMatches([showtimeFiltersIndex], query: compoundShowtimesQuery)

        return mergeMatches(originalMatches, complementaryMatches, query: query)
    }

    return nil
  }

  private func compoundCinemaMatches(query: String) -> [SearchMatch]? {
    if let compoundCinemasPatternMatch = re.search(compoundCinemasPattern, query),
      filteredQuery = compoundCinemasPatternMatch.group().flatMap({ query.replace($0, with: "") }),
      compoundCinemasQuery = compoundCinemasPatternMatch.group(1)?.trim() {
        let originalMatches = findMatches([nowPlayingMoviesIndex, movieFiltersIndex], query: filteredQuery)
        let complementaryMatches = findMatches([cinemasIndex], query: compoundCinemasQuery)

        return mergeMatches(originalMatches, complementaryMatches, query: query)
    }

    return nil
  }

  private func findMatches(indices: [SearchIndex], query: String) -> [SearchMatch] {
    return indices
      .map { $0.map { (score: $0.query.score(query, fuzziness: 0.5), item: $0) } }
      .flatten()
      .filter { $0.score > 0.4 }
  }

  private func mergeMatches(originalMatches: [SearchMatch], _ complementaryMatches: [SearchMatch], query: String)
    -> [SearchMatch] {
      return originalMatches
        .filter { $0.score > 0.5 }
        .map { originalMatch -> [SearchMatch] in
          return complementaryMatches.map { complementaryMatch in
            let item = SearchItem(components: originalMatch.item.components + complementaryMatch.item.components)
            return (score: item.query.score(query, fuzziness: 0.5), item: item)
          }
        }
        .flatten()
        .flatMap { $0 }
  }
}
