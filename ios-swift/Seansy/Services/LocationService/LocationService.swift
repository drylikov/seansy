import CoreLocation
import Foundation
import RxSwift

final class LocationService: NSObject {

  // MARK: Inputs

  let monitor: Bool

  // MARK: Public properties

  private(set) var isRunning = false

  var locateByIp: Observable<Address> {
    log.info("📍 Getting user's location by IP")
    return ipApiProvider.request(Geolocate())
      .timeout(4.0, scheduler: ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default))
      .mapObject(Address.self)
      .flatMap {
        $0.city == nil
          ? Observable.just($0)
          : self.geocodingApiProvider.request(.Address($0.city!)).mapGeocodingResults()
    }
  }

  // MARK: Private properties

  private lazy var locationSubject = PublishSubject<CLLocation>()
  private lazy var addressSubject = PublishSubject<Address>()
  private lazy var locationManager: CLLocationManager = {
    return CLLocationManager().then { $0.delegate = self }
  }()
  private lazy var geocodingApiProvider = GeocodingAPIProvider()
  private lazy var ipApiProvider = IPAPIProvider()

  // MARK: Initialization

  init(monitor: Bool = false, desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest) {
    self.monitor = monitor
    super.init()

    locationManager.desiredAccuracy = desiredAccuracy
  }

  // MARK: Public methods

  func start() -> Observable<CLLocation> {
    if !isRunning {
      locationManager.startUpdatingLocation()
      isRunning = true
    }

    return locationSubject.asObservable()
  }

  func stop() {
    locationManager.stopUpdatingLocation()
    isRunning = false
  }

  func reverseGeocodeLocation(location: CLLocation) -> Observable<Address> {
    log.info("📍 Reverse geocoding \(location)")
    return geocodingApiProvider
      .request(.Coordinate(location.coordinate))
      .mapGeocodingResults()
      .flatMap { $0.city != nil ? Observable.just($0) : self.locateByIp  }
  }

  func getAddress(byIp byIp: Bool = false) -> Observable<Address> {
    return byIp ? locateByIp : start().flatMap(reverseGeocodeLocation)
  }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    locationSubject.onError(error)
  }

  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.last {
      locationSubject.onNext(location)
      if !monitor {
        locationSubject.onCompleted()
        stop()
      }
    }
  }
}
