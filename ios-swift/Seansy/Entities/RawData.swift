import Foundation

typealias City = String

struct RawData {

  // MARK: Public properties

  var movies: [Movie]?
  var cinemas: [Cinema]?
  var showtimes = [City: [Showtime]]()
  var isComplete: Bool { return movies != nil && cinemas != nil && showtimes.isEmpty }

  // MARK: Public methods

  func showtimes(city city: City? = nil) -> [Showtime]? {
    if showtimes.isEmpty { return nil }
    return city.flatMap { showtimes[$0] } ?? showtimes.values.flatMap { $0 }
  }
}
