import CoreLocation
import NSObject_Rx
import RxSwift
import Foundation

final class LocationRequestInteractor: NSObject {

  // MARK: Private properties

  private let dataManager: DataManager
  private let doneClosure: Bool -> Void
  private lazy var locationService = LocationService(monitor: false, desiredAccuracy: kCLLocationAccuracyHundredMeters)

  // MARK: Initialization

  init(dataManager: DataManager, doneClosure: Bool -> Void) {
    self.dataManager = dataManager
    self.doneClosure = doneClosure
    super.init()
  }

  // MARK: Public methods

  func updateCity(byIp byIp: Bool) {
    doneClosure(!byIp)
    locationService.getAddress(byIp: byIp)
      .catchError { error in
        log.error("Failed to get user location: \(error)")
        return Observable.just(Address())
      }
      .map { $0.city }
      .subscribeNext(dataManager.updateCity)
      .addDisposableTo(rx_disposeBag)
  }
}
