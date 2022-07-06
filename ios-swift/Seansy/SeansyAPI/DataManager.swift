import NSObject_Rx
import RxCocoa
import RxSwift
import SwiftDate
import SwiftyUserDefaults
import UIKit

final class DataManager: NSObject {

  // MARK: Inputs

  let seansyApiProvider: SeansyAPIProvider
  let application: UIApplication?

  // MARK: Public properties

  private(set) lazy var rawData = RawData()
  private(set) lazy var formattedData: FormattedData = {
    return FormattedData(updateSubject: self.dataUpdateSubject)
  }()

  var movieFilters: MovieFilters? { return formattedData.movieFilters }
  private(set) var moviesSortBy: MoviesSortBy {
    get { return formattedData.moviesSortBy }
    set { formattedData.moviesSortBy = newValue }
  }
  private(set) var cinemasSortBy: CinemasSortBy {
    get { return formattedData.cinemasSortBy }
    set { formattedData.cinemasSortBy = newValue }
  }
  private(set) var selectedDate: NSDate {
    get { return formattedData.date }
    set { formattedData.date = newValue }
  }
  private(set) var selectedCity: City? = Cache[.selectedCity] ?? (Cache[.didRequestLocation] ? "Алматы" : nil) {
    didSet { Cache[.selectedCity] = selectedCity }
  }
  var backdropColors = Cache[.backdropColors]
    .flatMap { NSKeyedUnarchiver.unarchiveObjectWithData($0) as? [NSURL: BackdropColors] } ?? [:]
  var recentSearches: [SearchItem] {
    let items: [SearchItem] = (featuredMovies?[0..<2].map { SearchItem(movie: $0) } ?? []) + [
      SearchItem(query: "Приключения", type: .MovieFilters),
      SearchItem(query: "Достык плаза", type: .CinemaFilters),
      SearchItem(query: "Дивергент после обеда", type: .ShowtimeFilters)
    ]
    return items.shuffle()
  }
  //  var recentSearches = Cache[.recentSearches]
  //    .flatMap { NSKeyedUnarchiver.unarchiveObjectWithData($0) as? [SearchItem] } ?? []
  var searchEngine: SearchEngine {
    return SearchEngine(movies: rawData.movies ?? [], cinemas: formattedData.cinemas ?? [])
  }
  private(set) lazy var dates: [NSDate] = [today, today + 1.days]

  // Observables emitting updated data
  var dataUpdates: Observable<DataUpdate> { return dataUpdateSubject.asObservable() }
  var selectedDateUpdates: Observable<NSDate> { return selectedDateUpdateSubject.asObservable() }
  var selectedCityUpdates: Observable<City> { return selectedCityUpdateSubject.asObservable() }
  var reachableUpdates: Driver<Bool> { return reachable.asDriver() }

  // Updating observables
  var updateMovies: Observable<Movies> {
    return dataObservable == nil ? getMovies(forceReload: true) : Observable.empty()
  }
  var updateShowtimes: Observable<Showtimes> {
    return dataObservable == nil ? getShowtimes(forceReload: true) : Observable.empty()
  }

  // MARK: Private properties

  private var activeConnections = 0 {
    didSet { application?.networkActivityIndicatorVisible = activeConnections > 0 }
  }
  private var reachable = Variable(true)

  private var loadData: Observable<FormattedData> {
    if let dataObservable = dataObservable { return dataObservable }

    let observable = Observable
      .zip(getMovies(), getCinemas(), getShowtimes()) { _ in self.formattedData }
      .doOn { event in
        switch event {
        case .Error, .Completed: self.dataObservable = nil
        default: break
        }
      }
      .shareReplay(1)
    dataObservable = observable

    return observable
  }

  // Update subjects
  private lazy var dataUpdateSubject = PublishSubject<DataUpdate>()
  private lazy var selectedDateUpdateSubject = PublishSubject<NSDate>()
  private lazy var selectedCityUpdateSubject = PublishSubject<City>()

  // Cached objects
  private var cachedMovies: [Movie]? {
    var dataExpired = false
    if reachable.value {
      dataExpired = Cache[Seansy.Movies.lastUpdateDateKey]
        .flatMap { $0 < .lastMoviesUpdateDate || $0 < .lastShowtimesUpdateDate } ?? true
    }
    return dataExpired ? nil : Cache[Seansy.Movies.cachedDataKey]
      .flatMap { NSKeyedUnarchiver.unarchiveObjectWithData($0) as? [Movie] }
  }
  private var cachedShowtimes: [Showtime]? {
    var dataExpired = false
    if reachable.value {
      dataExpired = Cache[Seansy.Showtimes(selectedCity).lastUpdateDateKey]
        .flatMap { $0 < .lastShowtimesUpdateDate } ?? true
    }
    return dataExpired ? nil : Cache[Seansy.Showtimes(selectedCity).cachedDataKey]
      .flatMap { NSKeyedUnarchiver.unarchiveObjectWithData($0) as? [Showtime] }
  }
  private var cachedCinemas: [Cinema]? {
    var dataExpired = false
    if reachable.value {
      dataExpired = Cache[Seansy.Cinemas.lastUpdateDateKey]
        .flatMap { $0 < .lastShowtimesUpdateDate } ?? true
    }
    return dataExpired ? nil : Cache[Seansy.Cinemas.cachedDataKey]
      .flatMap { NSKeyedUnarchiver.unarchiveObjectWithData($0) as? [Cinema] }
  }

  private var dataObservable: Observable<FormattedData>?
  private lazy var reachabilityService = ReachabilityService.sharedReachabilityService

  // MARK: Initialization

  init(seansyApiProvider: SeansyAPIProvider, application: UIApplication? = nil) {
    self.seansyApiProvider = seansyApiProvider
    self.application = application
    super.init()

    reachabilityService.reachabilityChanged
      .distinctUntilChanged()
      .map { (status: ReachabilityStatus) -> Bool in status == .Reachable }
      .bindTo(reachable)
      .addDisposableTo(rx_disposeBag)
  }

  // MARK: Public methods

  func startLoading() {
    loadData.subscribe().addDisposableTo(rx_disposeBag)
  }

  func resortMovies(sortBy: MoviesSortBy) {
    if moviesSortBy == sortBy { return }

    formattedData.moviesSortBy = sortBy
    log.info("🔁 Resorted movies by \(sortBy)")
  }

  func refilterMovies() {
    guard let filters = movieFilters else { return }

    let filtersString = "minimum rating: \(filters.ratingFilter), maximum runtime: \(filters.runtimeFilter), " +
    "children: \(filters.childrenFilter), genres: \(filters.genresFilter)"
    log.info("🔁 Refiltered movies with \(filtersString)")
    formattedData.refreshMovies()
  }

  func selectDate(date: NSDate) {
    if date == selectedDate { return }

    selectedDate = date
    selectedDateUpdateSubject.onNext(date)
    log.info("🔁 Selected date \(date)")
  }

  func updateCity(city: City?) {
    loadData
      .map { _ in
        if let cities = self.rawData.cinemas?.cities, city = city {
          if cities.contains(city) { return city }
          log.info("City \"\(city)\" unsupported, switching to Almaty")
        }

        return "Алматы"
      }
      .flatMap(selectCity)
      .subscribe()
      .addDisposableTo(rx_disposeBag)
  }

  func selectCity(city: City) -> Observable<Bool> {
    if city == selectedCity { return Observable.just(false) }

    selectedCity = city
    selectedCityUpdateSubject.onNext(city)
    log.info("🏙 Selected city \(city)")
    formattedData.setCinemas(rawData.cinemas?.filter { $0.city == city })

    if rawData.showtimes.keys.contains(city) {
      formattedData.setShowtimes(rawData.showtimes(city: city))
      return Observable.just(true)
    } else {
      return getShowtimes().map { _ in true }
    }
  }
}

// MARK: - Private Data Loading Methods

private extension DataManager {
  func getMovies(forceReload forceReload: Bool = false) -> Observable<Movies> {
    if !forceReload {
      if let movies = formattedData.movies {
        return Observable.just(movies)
      } else if let movies = cachedMovies {
        log.info("💾 Loaded \(movies.count) movies from cache 💾")
        return Observable.just(setMovies(movies))
      }
    }

    let startDate = NSDate()
    return seansyApiProvider
      .request(.Movies)
      .mapArray(Movie.self, rootKey: "data")
      .dataConnection(startConnection, endConnection)
      .retryOnBecomesReachable(cachedMovies ?? [], reachabilityService: reachabilityService)
      .map { movies in
        let timeElapsed = String(format: "%.2f seconds", NSDate().timeIntervalSinceDate(startDate))
        log.info("⬇️ Downloaded \(movies.count) movies in \(timeElapsed) ⬇️")

        self.updateCache(.Movies, object: movies)
        return self.setMovies(movies)
      }
      .doOnError { log.error("Failed to download movies: \($0)") }
  }

  func getCinemas(forceReload forceReload: Bool = false) -> Observable<Cinemas> {
    if !forceReload {
      if let cinemas = formattedData.cinemas {
        return Observable.just(cinemas)
      } else if let cinemas = cachedCinemas {
        log.info("💾 Loaded \(cinemas.count) cinemas from cache 💾")
        return Observable.just(setCinemas(cinemas))
      }
    }

    let startDate = NSDate()
    return seansyApiProvider
      .request(.Cinemas)
      .mapArray(Cinema.self, rootKey: "data")
      .retryOnBecomesReachable(cachedCinemas ?? [], reachabilityService: reachabilityService)
      .dataConnection(startConnection, endConnection)
      .map { cinemas in
        let timeElapsed = String(format: "%.2f seconds", NSDate().timeIntervalSinceDate(startDate))
        log.info("⬇️ Downloaded \(cinemas.count) cinemas in \(timeElapsed) ⬇️")

        self.updateCache(.Cinemas, object: cinemas)
        return self.setCinemas(cinemas)
      }
      .doOnError { log.error("Failed to download cinemas: \($0)") }
  }

  func getShowtimes(forceReload forceReload: Bool = false) -> Observable<Showtimes> {
    if !forceReload {
      if let showtimes = formattedData.showtimes {
        return Observable.just(showtimes)
      } else if let showtimes = cachedShowtimes {
        log.info("💾 Loaded \(showtimes.count) showtimes from cache 💾")
        return Observable.just(setShowtimes(showtimes.groupedBy { $0.city }))
      }
    }

    let startDate = NSDate()
    let city = selectedCity != nil ? selectedCity! : "all cities"
    return seansyApiProvider
      .request(.Showtimes(selectedCity))
      .mapArray(Showtime.self, rootKey: "data")
      .dataConnection(startConnection, endConnection)
      .retryOnBecomesReachable(cachedShowtimes ?? [], reachabilityService: reachabilityService)
      .map { showtimes in
        let timeElapsed = String(format: "%.2f seconds", NSDate().timeIntervalSinceDate(startDate))
        log.info("⬇️ Downloaded \(showtimes.count) showtimes for \(city) in \(timeElapsed) ⬇️")

        let groupedShowtimes = showtimes.groupedBy { $0.city }
        groupedShowtimes.forEach { self.updateCache(.Showtimes($0), object: $1) }
        return self.setShowtimes(groupedShowtimes)
      }
      .doOnError { log.error("Failed to download showtimes: \($0)") }
  }

  private func updateCache(target: Seansy, object: AnyObject) {
    if !self.reachable.value { return }

    Cache[target.lastUpdateDateKey] = NSDate()
    Cache[target.cachedDataKey] = NSKeyedArchiver.archivedDataWithRootObject(object)
  }
  private func startConnection() { activeConnections = min(3, activeConnections + 1) }
  private func endConnection() { activeConnections = max(0, activeConnections - 1) }
}

// MARK: - Private Data Updating Methods

private extension DataManager {
  func setMovies(movies: [Movie]?) -> Movies {
    rawData.movies = movies
    return formattedData.setMovies(movies)
  }

  func setCinemas(cinemas: [Cinema]?) -> Cinemas {
    rawData.cinemas = cinemas
    return formattedData.setCinemas(selectedCity.flatMap { city in cinemas?.filter({ $0.city == city }) } ?? [])
  }

  func setShowtimes(showtimes: [City: [Showtime]]?) -> Showtimes {
    showtimes?.forEach { self.rawData.showtimes[$0] = $1 }
    return formattedData.setShowtimes(rawData.showtimes(city: selectedCity ?? "Алматы"))
  }
}

// MARK: - Private Observable Helpers

private extension Observable {
  func dataConnection(onSubscribed: () ->(), _ onDisposed: () -> ()) -> Observable<Element> {
    return Observable<Element>
      .using({ () -> AnonymousDisposable in onSubscribed(); return AnonymousDisposable(onDisposed) },
        observableFactory: { _ in return self })
  }
}
