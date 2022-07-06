import RxSwift
import SwiftDate

enum MoviesSortBy: Int {
  case Title, Popularity, Rating, ShowtimesCount
}

extension MoviesSortBy {
  var title: String {
    switch self {
    case .Title: return "По названию"
    case .Popularity: return "По популярности"
    case .Rating: return "По рейтингу"
    case .ShowtimesCount: return "По количеству сеансов"
    }
  }
  var asset: UIImage.Asset {
    switch self {
    case .Title: return .SortByName
    case .Popularity: return .SortByPopularity
    case .Rating: return .SortByRating
    case .ShowtimesCount: return .SortByShowtimesCount
    }
  }
  var description: String {
    switch self {
    case .Title: return "title"
    case .Popularity: return "popularity"
    case .Rating: return "rating"
    case .ShowtimesCount: return "showtimes count"
    }
  }
}

// MARK: -

enum CinemasSortBy: Int {
  case Name, Distance, Price, ShowtimesCount
}

extension CinemasSortBy {
  var title: String {
    switch self {
    case .Name: return "По названию"
    case .Distance: return "По расстоянию"
    case .Price: return "По средней цене"
    case .ShowtimesCount: return "По количеству сеансов"
    }
  }
  var asset: UIImage.Asset {
    switch self {
    case .Name: return .SortByName
    case .Distance: return .SortByDistance
    case .Price: return .SortByPrice
    case .ShowtimesCount: return .SortByShowtimesCount
    }
  }
  var description: String {
    switch self {
    case .Name: return "name"
    case .Distance: return "distance"
    case .Price: return "price"
    case .ShowtimesCount: return "showtimes count"
    }
  }
}

// MARK: - Movie Array Extension

extension SequenceType where Generator.Element == Movie {
  func sorted(sortBy: MoviesSortBy, showtimes: [String: [Showtime]]? = nil) -> [Generator.Element] {
    if sortBy == .ShowtimesCount && showtimes == nil { return sorted(.Popularity) }

    return sort { a, b in
      switch sortBy {
      case .Title:
        return a.title < b.title
      case .Popularity:
        if let aPopularity = a.popularity, bPopularity = b.popularity {
          return aPopularity < bPopularity
        } else {
          return a.popularity != nil && b.popularity == nil
        }
      case .Rating:
        return a.averageRating > b.averageRating
      case .ShowtimesCount:
        return showtimes.flatMap { $0[a.id]?.count ?? 0 > $0[b.id]?.count ?? 0 } ?? false
      }
    }
  }

  func filtered(filters: MovieFilters?, showtimes: [MovieId: [Showtime]]? = nil) -> [Generator.Element] {
    if let filters = filters {
      return filter { filters.combinedFilter($0) && showtimes?.keys.contains($0.id) ?? true }
    } else {
      return filter { showtimes?.keys.contains($0.id) ?? true }
    }
  }

  var groupedByDate: [NSDate: [Generator.Element]] {
    var dict: [NSDate: [Generator.Element]] = [:]
    for el in self {
      if let key = el.releaseDate {
        if case nil = dict[key]?.append(el) { dict[key] = [el] }
      }
    }

    return dict
  }

  var maxRating: Float? { return map { $0.averageRating }.maxElement() }
  var minRating: Float? { return map { $0.averageRating }.minElement() }
  var maxRuntime: Int? { return map { $0.runtime ?? 0 }.maxElement() }
  var minRuntime: Int? { return map { $0.runtime ?? 0 }.minElement() }
  var genres: [String] {
    var counts = [String: Int]()
    map { $0.genres ?? [] }.flatten().forEach {
      counts[$0] = (counts[$0] ?? 0) + 1
    }
    return counts.keys.sort { counts[$0] > counts[$1] }
  }
}

// MARK: - Cinema Array Extension

extension SequenceType where Generator.Element == Cinema {
  func sorted(sortBy: CinemasSortBy, showtimes: [String: [Showtime]]? = nil) -> [Generator.Element] {
    if sortBy == .ShowtimesCount && showtimes == nil { return sorted(.Name) }

    return sort { a, b in
      switch sortBy {
      case .Name:
        return a.name < b.name
      case .Distance:
        return false
      case .Price:
        return showtimes.flatMap { $0[a.id]?.averagePrice ?? 0 < $0[b.id]?.averagePrice ?? 0 } ?? false
      case .ShowtimesCount:
        return showtimes.flatMap { $0[a.id]?.count ?? 0 > $0[b.id]?.count ?? 0 } ?? false
      }
    }
  }

  var cities: [String] { return map { $0.city }.unique.sort() }
}

// MARK: - Showtime Array Extension

extension SequenceType where Generator.Element == Showtime {
  var averagePrice: Int {
    let showtimes = filter { $0.prices?.adult != nil }
    if showtimes.count == 0 { return 0 }

    return showtimes
      .reduce(0) { averagePrice, showtime in
        return showtime.prices?.adult.flatMap { averagePrice + $0 } ?? averagePrice
      } / showtimes.count
  }
}

// MARK: - NSDate Helpers

extension NSDate {
  static var lastShowtimesUpdateDate: NSDate {
    let now = NSDate()
    let startOfDay = now.startOfDayInAlmaty

    if now < startOfDay + 8.hours {
      return startOfDay + 11.hours - 1.days
    } else if now > startOfDay + 8.hours && now < startOfDay + 11.hours {
      return startOfDay + 8.hours
    } else {
      return startOfDay + 11.hours
    }
  }

  static var lastMoviesUpdateDate: NSDate {
    let now = NSDate()
    let startOfDay = now.startOfDayInAlmaty

    return startOfDay + 3.hours - (now < startOfDay + 3.hours ? 1 : 0).days
  }
}
