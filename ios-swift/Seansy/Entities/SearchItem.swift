import Foundation

final class SearchItem: NSObject, NSCoding {

  // MARK: Private types

  private enum Key {
    static let components = "components"
    static let imageUrl = "imageUrl"
  }

  // MARK: Inputs

  let components: [SearchItemComponent]
  let imageUrl: NSURL?

  // MARK: Public properties

  var type: SearchItemComponent.ComponentType {
    return components.count > 1 ? .ShowtimeFilters : components.first!.type
  }
  var query: String {
    let firstComponent = components.first!

    if components.count == 1 {
      return firstComponent.type == .ShowtimeFilters ? "Сеансы \(firstComponent.query)" : firstComponent.query
    } else {
      if firstComponent.type == .MovieTitle || firstComponent.type == .MovieFilters {
        return components.map { $0.type == .CinemaName ? "в \($0.query)" : $0.query }.joinWithSeparator(" ")
      } else {
        return components.map { $0.query }.joinWithSeparator(" ")
      }
    }
  }
  var subtitle: String {
    switch type {
    case .MovieTitle: return "Фильм"
    case .CinemaName: return "Кинотеатр"
    case .MovieFilters: return "Фильмы"
    case .CinemaFilters: return "Кинотеатры"
    case .ShowtimeFilters: return "Сеансы"
    }
  }
  var bigAsset: UIImage.Asset {
    switch type {
    case .MovieTitle, .MovieFilters: return .SearchMovieIconBig
    case .CinemaName, .CinemaFilters: return .SearchCinemaIconBig
    case .ShowtimeFilters: return .SearchClockIconBig
    }
  }
  var smallAsset: UIImage.Asset {
    switch type {
    case .MovieTitle, .MovieFilters: return .SearchMovieIconSmall
    case .CinemaName, .CinemaFilters: return .SearchCinemaIconSmall
    case .ShowtimeFilters: return .SearchClockIconSmall
    }
  }

  // Public subscripts

  subscript(componentType: SearchItemComponent.ComponentType) -> SearchItemComponent? {
    return components.find { $0.type == componentType }
  }

  // MARK: Initialization

  init(components: [SearchItemComponent]) {
    self.components = components.sort { $0.precedence < $1.precedence }
    imageUrl = nil
  }

  init(query: String, type: SearchItemComponent.ComponentType) {
    components = [SearchItemComponent(query: query, type: type)]
    imageUrl = nil
  }

  init(movie: Movie) {
    components = [SearchItemComponent(movie: movie)]
    imageUrl = movie.posterUrl
  }

  init(cinema: Cinema) {
    components = [SearchItemComponent(cinema: cinema)]
    imageUrl = cinema.photoUrl
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    components = aDecoder.decodeObjectForKey(Key.components) as! [SearchItemComponent]
    imageUrl = aDecoder.decodeObjectForKey(Key.imageUrl) as? NSURL
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(components, forKey: Key.components)
    aCoder.encodeObject(imageUrl, forKey: Key.imageUrl)
  }
}

// MARK: - Equatable

func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
  return lhs.query == rhs.query && lhs.type == rhs.type
}
