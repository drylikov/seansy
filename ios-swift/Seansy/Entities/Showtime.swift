import Foundation
import SwiftDate
import Unbox
import Secrets

private let ticketonRootUrl = "https://m.ticketon.kz"

final class Showtime: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let id = "_id"
    static let movieId = "movieId"
    static let cinemaId = "cinemaId"
    static let city = "city"
    static let time = "time"
    static let format = "format"
    static let language = "language"
    static let prices = "prices"
    static let ticketonId = "ticketonId"
  }

  // MARK: Inputs

  let id: String
  let movieId: String
  let cinemaId: String
  let city: String
  let time: NSDate
  let format: String?
  let language: String?
  let prices: ShowtimePrices?
  let ticketonId: String?

  // MARK: Public properties

  var passed: Bool { return time < NSDate() }
  var ticketonUrl: NSURL? {
    if passed { return nil }
    return ticketonId.flatMap { NSURL(string: "\(ticketonRootUrl)/show/\($0)?token=\(Secrets.ticketonToken)") }
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    id = unboxer.unbox(Key.id)
    movieId = unboxer.unbox(Key.movieId)
    cinemaId = unboxer.unbox(Key.cinemaId)
    city = unboxer.unbox(Key.city)
    time = unboxer.unbox(Key.time, formatter: jsonDateFormmatter).dateByAddingTimeInterval(timezoneOffset)
    format = unboxer.unbox(Key.format)
    language = unboxer.unbox(Key.language)
    prices = unboxer.unbox(Key.prices)
    ticketonId = unboxer.unbox(Key.ticketonId)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    id = aDecoder.decodeObjectForKey(Key.id) as! String
    movieId = aDecoder.decodeObjectForKey(Key.movieId) as! String
    cinemaId = aDecoder.decodeObjectForKey(Key.cinemaId) as! String
    city = aDecoder.decodeObjectForKey(Key.city) as! String
    time = aDecoder.decodeObjectForKey(Key.time) as! NSDate
    format = aDecoder.decodeObjectForKey(Key.format) as? String
    language = aDecoder.decodeObjectForKey(Key.language) as? String
    prices = aDecoder.decodeObjectForKey(Key.prices) as? ShowtimePrices
    ticketonId = aDecoder.decodeObjectForKey(Key.ticketonId) as? String
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(id, forKey: Key.id)
    aCoder.encodeObject(movieId, forKey: Key.movieId)
    aCoder.encodeObject(cinemaId, forKey: Key.cinemaId)
    aCoder.encodeObject(city, forKey: Key.city)
    aCoder.encodeObject(time, forKey: Key.time)
    aCoder.encodeObject(format, forKey: Key.format)
    aCoder.encodeObject(language, forKey: Key.language)
    aCoder.encodeObject(prices, forKey: Key.prices)
    aCoder.encodeObject(ticketonId, forKey: Key.ticketonId)
  }

  // MARK: Public methods

  func detailsString(movie: Movie) -> NSAttributedString {
    let priceString: (prefix: String, price: Int) -> NSAttributedString = { prefix, price in
      return NSMutableAttributedString(
        string: "\(prefix): ",
        attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(16) ]).then {
          $0.appendAttributedString(
            NSAttributedString(string: "\(price)", attributes: [ NSFontAttributeName: UIFont.semiboldFontOfSize(16) ])
          )
          $0.appendAttributedString(
            NSAttributedString(string: "тг", attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(16) ])
          )
      }
    }

    var attributedStrings = [prices?.adult.flatMap { priceString(prefix: "взрослый", price: $0) },
      prices?.children.flatMap { priceString(prefix: "детский", price: $0) },
      prices?.student.flatMap { priceString(prefix: "студенческий", price: $0) },
      prices?.vip.flatMap { priceString(prefix: "VIP", price: $0) }].flatMap { $0 }
    if let runtime = movie.runtime {
      let startTime = timeDateFormatter.stringFromDate(time)
      let endTime = timeDateFormatter.stringFromDate(time + runtime.minutes)
      var metaString = "\(startTime) ~ \(endTime)"
      if let language = language { metaString += " (\(language) яз.)" }
      attributedStrings.append(
        NSAttributedString(
          string: metaString,
          attributes: [
            NSFontAttributeName: UIFont.regularFontOfSize(16),
            NSForegroundColorAttributeName: UIColor.blackColor().alpha(0.7)
          ])
      )
    }
    attributedStrings = attributedStrings.enumerate().map { index, attributedString in
      return index > 0
        ? NSMutableAttributedString(string: "\n").then { $0.appendAttributedString(attributedString) }
        : attributedString
    }

    return attributedStrings.reduce(NSMutableAttributedString(string: "")) {
      $0.appendAttributedString($1)
      return $0
    }
  }

  func summaryString(cinema: Cinema? = nil) -> NSAttributedString {
    var attributedStrings = [NSAttributedString]()

    if let cinema = cinema {
      attributedStrings.append(
        NSAttributedString(string: cinema.name, attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(14) ])
      )
    } else {
      attributedStrings.append(
        NSAttributedString(
          string: timeDateFormatter.stringFromDate(time),
          attributes: [ NSFontAttributeName: UIFont.slabFontOfSize(18) ]
        )
      )
    }

    if let format = format {
      attributedStrings.append(
        NSAttributedString(
          string: "\n\(format)",
          attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(14) ]
        )
      )
    }
    if ticketonUrl != nil {
      attributedStrings.append(
        NSAttributedString(
          string: attributedStrings.count == 1 ? "\n" : " ",
          attributes: [ NSFontAttributeName: UIFont.regularFontOfSize(14) ]
        )
      )
      attributedStrings.append(
        NSAttributedString(attachment: NSTextAttachment()
          .then { $0.image = UIImage(.TicketIcon).icon })
      )
    }

    return attributedStrings.reduce(NSMutableAttributedString(string: "")) {
      $0.appendAttributedString($1)
      return $0
    }
  }
}

// MARK: - Equatable

func == (lhs: Showtime, rhs: Showtime) -> Bool {
  return lhs.id == rhs.id
}
