import Foundation
import Unbox

final class MovieRating: NSObject, NSCoding {

  // MARK: Public types

  enum RatingType: Int {
    case Kinopoisk, IMDB, RTCritics, RTAudience, Metacritic
  }

  // MARK: Private types

  private enum Key {
    static let value = "value"
    static let type = "type"
  }

  // MARK: Inputs

  let value: Float
  let type: RatingType

  // MARK: Public properties

  var attributedString: NSAttributedString {
    switch type {
    case .Kinopoisk, .IMDB:
      return NSMutableAttributedString(
        string: String(format: "%.1f", value),
        attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(18) ]).then {
          $0.appendAttributedString(
            NSAttributedString(string: "/10", attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(12) ])
          )
      }
    case .RTCritics, .RTAudience, .Metacritic:
      return NSAttributedString(
        string: "\(Int(value))%",
        attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(18) ]
      )
    }
  }

  var asset: UIImage.Asset? {
    switch type {
    case .Kinopoisk:
      return .Kinopoisk
    case .IMDB:
      return .IMDB
    case .RTCritics:
      return value < 60 ? .RottenTomato : .FreshTomato
    case .RTAudience:
      return value < 60 ? .FallenPopcorn : .StandingPopcorn
    default: return nil
    }
  }

  // MARK: Initialization

  init(value: Float, type: MovieRating.RatingType) {
    self.value = value
    self.type = type
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    value = aDecoder.decodeFloatForKey(Key.value)
    type = RatingType(rawValue: aDecoder.decodeIntegerForKey(Key.type))!
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeFloat(value, forKey: Key.value)
    aCoder.encodeInteger(type.rawValue, forKey: Key.type)
  }
}

// MARK: -

final class MovieRatings: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let kinopoisk = "kinopoisk"
    static let imdb = "imdb"
    static let rtCritics = "rtCritics"
    static let rtAudience = "rtAudience"
    static let metacritic = "metacritic"
  }

  // MARK: Public properties

  var empty: Bool {
    return kinopoisk == nil && imdb == nil && rtCritics == nil && rtAudience == nil && metacritic == nil
  }

  // MARK: Public subscripts

  subscript(ratingType: MovieRating.RatingType) -> MovieRating? {
    switch ratingType {
    case .Kinopoisk: return kinopoisk
    case .IMDB: return imdb
    case .RTCritics: return rtCritics
    case .RTAudience: return rtAudience
    case .Metacritic: return metacritic
    }
  }

  // MARK: Private properties

  private let kinopoisk: MovieRating?
  private let imdb: MovieRating?
  private let rtCritics: MovieRating?
  private let rtAudience: MovieRating?
  private let metacritic: MovieRating?

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    kinopoisk = (unboxer.unbox(Key.kinopoisk) as Float?).flatMap { MovieRating(value: $0, type: .Kinopoisk) }
    imdb = (unboxer.unbox(Key.imdb) as Float?).flatMap { MovieRating(value: $0, type: .IMDB) }
    rtCritics = (unboxer.unbox(Key.rtCritics) as Int?).flatMap { MovieRating(value: Float($0), type: .RTCritics) }
    rtAudience = (unboxer.unbox(Key.rtAudience) as Int?).flatMap { MovieRating(value: Float($0), type: .RTAudience) }
    metacritic = (unboxer.unbox(Key.metacritic) as Int?).flatMap { MovieRating(value: Float($0), type: .Metacritic) }
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    kinopoisk = aDecoder.decodeObjectForKey(Key.kinopoisk) as? MovieRating
    imdb = aDecoder.decodeObjectForKey(Key.imdb) as? MovieRating
    rtCritics = aDecoder.decodeObjectForKey(Key.rtCritics) as? MovieRating
    rtAudience = aDecoder.decodeObjectForKey(Key.rtAudience) as? MovieRating
    metacritic = aDecoder.decodeObjectForKey(Key.metacritic) as? MovieRating
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(kinopoisk, forKey: Key.kinopoisk)
    aCoder.encodeObject(imdb, forKey: Key.imdb)
    aCoder.encodeObject(rtCritics, forKey: Key.rtCritics)
    aCoder.encodeObject(rtAudience, forKey: Key.rtAudience)
    aCoder.encodeObject(metacritic, forKey: Key.metacritic)
  }

  // MARK: Public methods

  func rating(ratingType: MovieRating.RatingType) -> Float? { return self[ratingType]?.value }
}
