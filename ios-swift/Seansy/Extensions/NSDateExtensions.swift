import Foundation
import SwiftDate

let timezoneOffset = Double(NSTimeZone.defaultTimeZone().secondsFromGMT)
let jsonDateFormmatter = NSDateFormatter().then { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" }
let timeDateFormatter = NSDateFormatter().then {
  $0.timeZone = NSTimeZone(name: "Asia/Almaty")
  $0.dateFormat = "HH:mm"
}
let iso8601Formatter = NSDateFormatter().then {
  $0.timeZone = NSTimeZone(name: "Asia/Almaty")
  $0.dateFormat = "yyyy-MM-dd"
}
let compactDateFormatter = NSDateFormatter().then {
  $0.timeZone = NSTimeZone(name: "Asia/Almaty")
  $0.locale = NSLocale(localeIdentifier: "ru")
  $0.dateFormat = NSDateFormatter.dateFormatFromTemplate("MMMMd", options: 0, locale: $0.locale)
}
let fullDateFormatter = NSDateFormatter().then {
  $0.timeZone = NSTimeZone(name: "Asia/Almaty")
  $0.locale = NSLocale(localeIdentifier: "ru")
  $0.dateFormat = NSDateFormatter.dateFormatFromTemplate("MMMMdyyyy", options: 0, locale: $0.locale)
}
let today = NSDate().startOfDayInAlmaty

extension NSDate {
  var daysToDate: Int {
    return components(.Day, fromDate: NSDate(), toDate: self, options: []).day
  }
  var weeksToDate: Int {
    return components(.WeekOfYear, fromDate: NSDate(), toDate: self, options: []).weekOfYear
  }
  var yearsToDate: Int {
    return components(.Year, fromDate: NSDate(), toDate: self, options: []).year
  }

  var shortReleaseDateString: String {
    return (inRegion().year != NSDate().inRegion().year ? fullDateFormatter : compactDateFormatter).stringFromDate(self)
  }

  var longReleaseDateString: String {
    if weeksToDate >= 1 {
      return "\(shortReleaseDateString) - через \(weeksToDate.pluralize(["неделю", "недели", "недель"]))"
    } else if weeksToDate < 0 {
      return "\(shortReleaseDateString) - \(abs(weeksToDate).pluralize(["неделю", "недели", "недель"])) назад"
    } else if daysToDate == 1 {
      return "\(shortReleaseDateString) - завтра"
    } else if daysToDate == -1 {
      return "\(shortReleaseDateString) - вчера"
    } else if daysToDate > 1 {
      return "\(shortReleaseDateString) - через \(daysToDate.pluralize(["день", "дня", "дней"]))"
    } else {
      return "\(shortReleaseDateString) - \(abs(daysToDate).pluralize(["день", "дня", "дней"])) назад"
    }
  }

  var shortDateMenuString: String {
    if self == today {
      return "на сегодня"
    } else if self == today + 1.days {
      return "на завтра"
    } else {
      return ""
    }
  }

  var longDateMenuString: String {
    if self == today {
      return "Сегодня (\(compactDateFormatter.stringFromDate(self)))"
    } else if self == today + 1.days {
      return "Завтра (\(compactDateFormatter.stringFromDate(self)))"
    } else {
      return compactDateFormatter.stringFromDate(self)
    }
  }

  var dayInAlmaty: Int { return inRegion(Region(timeZoneName: .AsiaAlmaty)).components.day }
  var startOfDayInAlmaty: NSDate { return startOf(.Day, inRegion: Region(timeZoneName: .AsiaAlmaty)) }
  var endOfDayInAlmaty: NSDate { return endOf(.Day, inRegion: Region(timeZoneName: .AsiaAlmaty)) }

  // MARK: Private methods

  private func components(unitFlags: NSCalendarUnit, fromDate startingDate: NSDate, toDate resultDate: NSDate,
    options opts: NSCalendarOptions) -> NSDateComponents {
      return NSCalendar.currentCalendar()
        .components(unitFlags, fromDate: startingDate, toDate: resultDate, options: opts)
  }
}
