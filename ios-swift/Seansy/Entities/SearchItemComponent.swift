import Foundation

final class SearchItemComponent: NSObject, NSCoding {

  // MARK: Public types

  enum ComponentType: Int {
    case MovieTitle, CinemaName, MovieFilters, CinemaFilters, ShowtimeFilters
  }

  // MARK: Private types

  private enum Key {
    static let query = "query"
    static let type = "type"
  }

  // MARK: Inputs

  let query: String
  let type: ComponentType

  // MARK: Public properties

  var precedence: Int {
    switch type {
    case .MovieTitle, .MovieFilters: return 1
    case .CinemaName, .CinemaFilters: return 2
    case .ShowtimeFilters: return 3
    }
  }

  // MARK: Initialization

  init(query: String, type: ComponentType) {
    self.query = query
    self.type = type
  }

  init(movie: Movie) {
    query = movie.title
    type = .MovieTitle
  }

  init(cinema: Cinema) {
    query = cinema.name
    type = .CinemaName
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    query = aDecoder.decodeObjectForKey(Key.query) as! String
    type = ComponentType(rawValue: aDecoder.decodeIntegerForKey(Key.type))!
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(query, forKey: Key.query)
    aCoder.encodeInteger(type.rawValue, forKey: Key.type)
  }
}
