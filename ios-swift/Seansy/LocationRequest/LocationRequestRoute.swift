import Foundation

extension LocationRequestViewController {
  static func new(dataManager: DataManager, doneClosure: Bool -> Void) -> LocationRequestViewController {
    let interactor = LocationRequestInteractor(dataManager: dataManager, doneClosure: doneClosure)
    return LocationRequestViewController(interactor: interactor)
  }
}
