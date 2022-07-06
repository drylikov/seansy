import Foundation
import Unbox

enum MPAARating: String {
  case G = "G"
  case PG = "PG"
  case PG13 = "PG-13"
  case R = "R"
  case NC17 = "NC-17"
}

final class Movie: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let id = "_id"
    static let title = "title"
    static let originalTitle = "originalTitle"
    static let synopsis = "synopsis"
    static let ratings = "ratings"
    static let pressReviews = "pressReviews"
    static let popularity = "popularity"
    static let posterUrl = "posterUrl"
    static let backdropUrl = "backdropUrl"
    static let trailers = "trailers"
    static let genres = "genres"
    static let stills = "stills"
    static let crew = "crew"
    static let year = "year"
    static let countries = "countries"
    static let runtime = "runtime"
    static let ageRating = "ageRating"
    static let mpaaRating = "mpaaRating"
    static let bonusScene = "bonusScene"
    static let releaseDate = "releaseDate"
  }

  // MARK: Inputs

  let id: String
  let title: String
  let originalTitle: String?
  let synopsis: String?
  let ratings: MovieRatings?
  let pressReviews: [MoviePressReview]?
  let popularity: Int?
  let posterUrl: NSURL?
  let backdropUrl: NSURL?
  let trailers: [Trailer]?
  let genres: [String]?
  let stills: [NSURL]?
  let crew: MovieCrew?
  let year: Int?
  let countries: [String]?
  let runtime: Int?
  let ageRating: Int?
  let mpaaRating: MPAARating?
  let bonusScene: BonusScene?
  let releaseDate: NSDate?

  // MARK: Public properties

  var averageRating: Float {
    let normalizedRatings = [ratings?.rating(.Kinopoisk).flatMap { $0 * 10 },
      ratings?.rating(.IMDB).flatMap { $0 * 10 }, ratings?.rating(.RTCritics),
      ratings?.rating(.RTAudience), ratings?.rating(.Metacritic)].flatMap { $0 }

    return normalizedRatings.isEmpty ? 0 : normalizedRatings.reduce(0, combine: +) / Float(normalizedRatings.count)
  }
  var ageRatingString: String? { return ageRating.flatMap { "\($0)+" } }
  var shortReleaseDateString: String? { return releaseDate?.shortReleaseDateString }
  var longReleaseDateString: String? { return releaseDate?.longReleaseDateString }
  var genresString: String? { return genres?.joinWithSeparator(", ") }
  var runtimeString: String? {
    return runtime.flatMap { runtime in
      let hours = runtime / 60
      let minutes = runtime % 60

      if hours > 0 && minutes > 0 {
        return "\(hours.pluralize(["час", "часа", "часов"])) \(minutes.pluralize(["минута", "минуты", "минут"]))"
      } else if minutes == 0 {
        return "\(hours.pluralize(["час", "часа", "часов"]))"
      } else {
        return "\(minutes.pluralize(["минута", "минуты", "минут"]))"
      }
    }
  }
  var directorsString: String? { return crew?.directors?.map { $0.name }.joinWithSeparator(", ") }
  var writersString: String? { return crew?.writers?.map { $0.name }.joinWithSeparator(", ") }
  var bonusSceneString: String? { return bonusScene?.string }
  var subtitle: String? {
    let subtitleComps = [ageRatingString, genresString].flatMap { $0 }
    return subtitleComps.isEmpty ? nil : subtitleComps.joinWithSeparator(" • ")
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    id = unboxer.unbox(Key.id)
    title = unboxer.unbox(Key.title)
    originalTitle = unboxer.unbox(Key.originalTitle)
    synopsis = unboxer.unbox(Key.synopsis)
    ratings = unboxer.unbox(Key.ratings)
    pressReviews = unboxer.unbox(Key.pressReviews)
    popularity = unboxer.unbox(Key.popularity)
    posterUrl = unboxer.unbox(Key.posterUrl)
    backdropUrl = unboxer.unbox(Key.backdropUrl)
    trailers = unboxer.unbox(Key.trailers)
    genres = unboxer.unbox(Key.genres)
    stills = (unboxer.unbox(Key.stills) as [String]?)?.map { NSURL(string: $0)! }
    crew = unboxer.unbox(Key.crew)
    year = unboxer.unbox(Key.year)
    countries = unboxer.unbox(Key.countries)
    runtime = unboxer.unbox(Key.runtime)
    ageRating = unboxer.unbox(Key.ageRating)
    mpaaRating = (unboxer.unbox(Key.mpaaRating) as String?).flatMap { MPAARating(rawValue: $0) }
    bonusScene = unboxer.unbox(Key.bonusScene)
    releaseDate = (unboxer.unbox(Key.releaseDate) as String?).flatMap { jsonDateFormmatter.dateFromString($0) }
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    id = aDecoder.decodeObjectForKey(Key.id) as! String
    title = aDecoder.decodeObjectForKey(Key.title) as! String
    originalTitle = aDecoder.decodeObjectForKey(Key.originalTitle) as? String
    synopsis = aDecoder.decodeObjectForKey(Key.synopsis) as? String
    ratings = aDecoder.decodeObjectForKey(Key.ratings) as? MovieRatings
    pressReviews = aDecoder.decodeObjectForKey(Key.pressReviews) as? [MoviePressReview]
    popularity = aDecoder.decodeObjectForKey(Key.popularity) as? Int
    posterUrl = aDecoder.decodeObjectForKey(Key.posterUrl) as? NSURL
    backdropUrl = aDecoder.decodeObjectForKey(Key.backdropUrl) as? NSURL
    trailers = aDecoder.decodeObjectForKey(Key.trailers) as? [Trailer]
    genres = aDecoder.decodeObjectForKey(Key.genres) as? [String]
    stills = aDecoder.decodeObjectForKey(Key.stills) as? [NSURL]
    crew = aDecoder.decodeObjectForKey(Key.crew) as? MovieCrew
    year = aDecoder.decodeObjectForKey(Key.year) as? Int
    countries = aDecoder.decodeObjectForKey(Key.countries) as? [String]
    runtime = aDecoder.decodeObjectForKey(Key.runtime) as? Int
    ageRating = aDecoder.decodeObjectForKey(Key.ageRating) as? Int
    mpaaRating = (aDecoder.decodeObjectForKey(Key.mpaaRating) as? String).flatMap { MPAARating(rawValue: $0) }
    bonusScene = aDecoder.decodeObjectForKey(Key.bonusScene) as? BonusScene
    releaseDate = aDecoder.decodeObjectForKey(Key.releaseDate) as? NSDate
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(id, forKey: Key.id)
    aCoder.encodeObject(title, forKey: Key.title)
    aCoder.encodeObject(originalTitle, forKey: Key.originalTitle)
    aCoder.encodeObject(synopsis, forKey: Key.synopsis)
    aCoder.encodeObject(ratings, forKey: Key.ratings)
    aCoder.encodeObject(pressReviews, forKey: Key.pressReviews)
    aCoder.encodeObject(popularity, forKey: Key.popularity)
    aCoder.encodeObject(posterUrl, forKey: Key.posterUrl)
    aCoder.encodeObject(backdropUrl, forKey: Key.backdropUrl)
    aCoder.encodeObject(trailers, forKey: Key.trailers)
    aCoder.encodeObject(genres, forKey: Key.genres)
    aCoder.encodeObject(stills, forKey: Key.stills)
    aCoder.encodeObject(crew, forKey: Key.crew)
    aCoder.encodeObject(year, forKey: Key.year)
    aCoder.encodeObject(countries, forKey: Key.countries)
    aCoder.encodeObject(runtime, forKey: Key.runtime)
    aCoder.encodeObject(ageRating, forKey: Key.ageRating)
    aCoder.encodeObject(mpaaRating?.rawValue, forKey: Key.mpaaRating)
    aCoder.encodeObject(bonusScene, forKey: Key.bonusScene)
    aCoder.encodeObject(releaseDate, forKey: Key.releaseDate)
  }
}

// MARK: - Equatable

func == (lhs: Movie, rhs: Movie) -> Bool { return lhs.id == rhs.id }
