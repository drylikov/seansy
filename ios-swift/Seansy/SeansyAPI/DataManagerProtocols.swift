import Foundation
import RxCocoa
import RxSwift

// MARK: MoviesCustomizationInteractor

protocol MoviesCustomizationInteractor {
  var moviesSortBy: MoviesSortBy { get }
  var movieFilters: MovieFilters? { get }
  var movieFiltersUpdates: Observable<Bool> { get }
  func resortMovies(sortBy: MoviesSortBy)
  func refilterMovies()
}

extension DataManager: MoviesCustomizationInteractor {
  var movieFiltersUpdates: Observable<Bool> {
    return dataUpdates
      .filter { _, _, _, change in change != .Cinemas }
      .map { movies, _, _, _ in return !movies.isEmpty }
  }
}

// MARK: - CinemaCustomizationInteractor

protocol CinemaCustomizationInteractor {
  var cinemasSortBy: CinemasSortBy { get }
}

extension DataManager: CinemaCustomizationInteractor {}

// MARK: - BackdropColorsInteractor

protocol BackdropColorsInteractor {
  var backdropColors: [NSURL: BackdropColors] { get }
  func setBackdropColors(colors: BackdropColors, url: NSURL)
}

extension DataManager: BackdropColorsInteractor {
  func setBackdropColors(colors: BackdropColors, url: NSURL) {
    backdropColors[url] = colors
    Cache[.backdropColors] = NSKeyedArchiver.archivedDataWithRootObject(backdropColors)
  }
}

// MARK: - SelectedDateInteractor

protocol SelectedDateInteractor {
  var selectedDate: NSDate { get }
  var selectedDateUpdates: Observable<NSDate> { get }
  var dates: [NSDate] { get }
  func selectDate(date: NSDate)
}

extension DataManager: SelectedDateInteractor {}

// MARK: - SelectedCityInteractor

protocol SelectedCityInteractor {
  var selectedCity: City? { get }
  var selectedCityUpdates: Observable<City> { get }
  func updateCity(city: City?)
  func selectCity(city: City) -> Observable<Bool>
}

extension DataManager: SelectedCityInteractor {}

// MARK: - ReachabilityInteractor

protocol ReachabilityInteractor {
  var reachableUpdates: Driver<Bool> { get }
}

extension DataManager: ReachabilityInteractor {}
