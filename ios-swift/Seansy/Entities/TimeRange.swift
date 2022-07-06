import Foundation
import PySwiftyRegex
import SwiftDate

final class TimeRange: NSObject, NSCoding {

  // MARK: Private types

  private enum Key {
    static let start = "start"
    static let end = "end"
  }

  // MARK: Inputs

  let start: NSDate!
  let end: NSDate!

  // MARK: Initialization

  init(start: NSDate, end: NSDate) {
    self.start = start
    self.end = end
  }

  init?(query: String) {
    let (start, end) = TimeRange.parseQuery(query)
    self.start = start
    self.end = end

    super.init()

    if self.start == nil || self.end == nil { return nil }
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    start = aDecoder.decodeObjectForKey(Key.start) as! NSDate
    end = aDecoder.decodeObjectForKey(Key.end) as! NSDate
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(start, forKey: Key.start)
    aCoder.encodeObject(end, forKey: Key.end)
  }

  // MARK: Private methods

  private static func parseQuery(query: String) -> (start: NSDate?, end: NSDate?) {
    let replacements = [
      (pattern: "^(на|через) час$", replacement: "$1 1 час"),
      (pattern: "(.+) полчаса$", replacement: "$1 30 минут")
    ]
    let minutesRegex = "([1-6]0) минута?ы?"
    let hoursRegex = "([2-9]|1[0-2]?) часа?(?:ов)?"

    let timeQuery = replacements.reduce(query) { re.sub($1.pattern, $1.replacement, $0) }
    if timeQuery.hasPrefix("на") {
      if let minutes = timeQuery.findNumber("^на \(minutesRegex)$") {
        return (start: NSDate(), end: NSDate() + minutes.minutes)
      }
      if let hours = timeQuery.findNumber("^на \(hoursRegex)$") {
        return (start: NSDate(), end: NSDate() + hours.hours)
      }
    }
    if timeQuery.hasPrefix("через") {
      if let minutes = timeQuery.findNumber("^через \(minutesRegex)$") {
        return (start: NSDate() + minutes.minutes, end: NSDate().endOfDayInAlmaty)
      }
      if let hours = timeQuery.findNumber("^через \(hoursRegex)$") {
        return (start: NSDate() + hours.hours, end: NSDate().endOfDayInAlmaty)
      }
    }

    return (start: nil, end: nil)
  }
}

// MARK: - Private String Helpers

private extension String {
  func findNumber(pattern: String) -> Int? {
    return re.search(pattern, self)?.group(1).flatMap { Int($0) }
  }
}
