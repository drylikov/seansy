import Hue
import SwiftyUserDefaults
import UIKit

let screenBounds = UIScreen.mainScreen().bounds
let screenWidth = screenBounds.width
let screenHeight = screenBounds.height
var statusBarHeight: CGFloat { return UIApplication.sharedApplication().statusBarFrame.height }

extension DefaultsKeys {
  static let didRequestLocation = DefaultsKey<Bool>("didRequestLocation")
  static let moviesSortBy = DefaultsKey<Int?>("moviesSortBy")
  static let cinemasSortBy = DefaultsKey<Int?>("cinemasSortBy")
  static let usePercentRating = DefaultsKey<Bool>("usePercentRating")
  static let selectedCity = DefaultsKey<City?>("selectedCity")
  static let backdropColors = DefaultsKey<NSData?>("backdropColors")
  static let recentSearches = DefaultsKey<NSData?>("recentSearches")

  static let persistMovieFilters = DefaultsKey<Bool>("persistMovieFilters")
  static let movieRatingFilter = DefaultsKey<Double?>("movieRatingFilter")
  static let movieRuntimeFilter = DefaultsKey<Int?>("movieRuntimeFilter")
  static let movieChildrenFilter = DefaultsKey<Bool>("movieChildrenFilter")
  static let movieGenresFilter = DefaultsKey<[String]>("movieGenresFilter")
}

extension UIColor {
  static func primaryColor() -> UIColor { return .hex("#141414") }
  static func accentColor() -> UIColor { return .hex("#ffd54f") }

  static func flatGreenColor() -> UIColor { return .hex("50ae55") }
  static func flatRedColor() -> UIColor { return .hex("a1453d") }
}

extension UIFont {
  static func regularFontOfSize(fontSize: CGFloat) -> UIFont { return UIFont(name: "Lato-Regular", size: fontSize)! }
  static func italicFontOfSize(fontSize: CGFloat) -> UIFont { return UIFont(name: "Lato-Italic", size: fontSize)! }
  static func lightFontOfSize(fontSize: CGFloat) -> UIFont { return UIFont(name: "Lato-Light", size: fontSize)! }
  static func semiboldFontOfSize(fontSize: CGFloat) -> UIFont { return UIFont(name: "Lato-Semibold", size: fontSize)! }
  static func slabFontOfSize(fontSize: CGFloat) -> UIFont { return UIFont(name: "StreetSemiBold", size: fontSize)! }
}

extension UIImage {
  enum Asset: String {
    case BackIcon = "BackIcon"
    case CalendarIcon = "CalendarIcon"
    case CheckIcon = "CheckIcon"
    case CinemasIconFill = "CinemasIconFill"
    case CinemasIconOutline = "CinemasIconOutline"
    case ClearIcon = "ClearIcon"
    case CustomizeIcon = "CustomizeIcon"
    case DirectionsIcon = "DirectionsIcon"
    case DislikeIcon = "DislikeIcon"
    case FallenPopcorn = "FallenPopcorn"
    case FilterIcon = "FilterIcon"
    case FreshTomato = "FreshTomato"
    case Globe = "Globe"
    case IMDB = "IMDB"
    case IPhoneIcon = "iPhoneIcon"
    case Kinopoisk = "Kinopoisk"
    case LikeIcon = "LikeIcon"
    case LocationArrowIcon = "LocationArrowIcon"
    case LocationIcon = "LocationIcon"
    case MailIcon = "MailIcon"
    case MapIcon = "MapIcon"
    case MessageIcon = "MessageIcon"
    case MovieBackdropPlaceholder = "MovieBackdropPlaceholder"
    case MoviesIconFill = "MoviesIconFill"
    case MoviesIconOutline = "MoviesIconOutline"
    case NewsIconFill = "NewsIconFill"
    case NewsIconOutline = "NewsIconOutline"
    case NoteIcon = "NoteIcon"
    case PhoneIcon = "PhoneIcon"
    case PhotoIcon = "PhotoIcon"
    case PlayIcon = "PlayIcon"
    case PopcornIcon = "PopcornIcon"
    case PosterPlaceholder = "PosterPlaceholder"
    case QuestionIcon = "QuestionIcon"
    case RateIcon = "RateIcon"
    case RecommendIcon = "RecommendIcon"
    case ReloadIcon = "ReloadIcon"
    case RottenTomato = "RottenTomato"
    case SadFace = "SadFace"
    case SearchCinemaIconBig = "SearchCinemaIconBig"
    case SearchCinemaIconSmall = "SearchCinemaIconSmall"
    case SearchClockIconBig = "SearchClockIconBig"
    case SearchClockIconSmall = "SearchClockIconSmall"
    case SearchDefaultIconBig = "SearchDefaultIconBig"
    case SearchDefaultIconSmall = "SearchDefaultIconSmall"
    case SearchIcon = "SearchIcon"
    case SearchMovieIconBig = "SearchMovieIconBig"
    case SearchMovieIconSmall = "SearchMovieIconSmall"
    case SettingsIconFill = "SettingsIconFill"
    case SettingsIconOutline = "SettingsIconOutline"
    case ShowtimesIconFill = "ShowtimesIconFill"
    case ShowtimesIconOutline = "ShowtimesIconOutline"
    case SortByDistance = "SortByDistance"
    case SortByName = "SortByName"
    case SortByPopularity = "SortByPopularity"
    case SortByPrice = "SortByPrice"
    case SortByRating = "SortByRating"
    case SortByShowtimesCount = "SortByShowtimesCount"
    case SortByTime = "SortByTime"
    case SortIcon = "SortIcon"
    case StandingPopcorn = "StandingPopcorn"
    case StarIconFill = "StarIconFill"
    case StarIconOutline = "StarIconOutline"
    case TicketIcon = "TicketIcon"
    case WhatsAppIcon = "WhatsAppIcon"

    var image: UIImage {
      return UIImage(self)
    }
  }

  convenience init!(_ asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
