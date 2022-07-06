import CoreLocation
import Foundation
import Unbox

final class Location: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let latitude = "lat"
    static let longitude = "lng"
  }

  // MARK: Inputs

  let latitude: Double
  let longitude: Double

  // MARK: Public properties

  var coreLocation: CLLocation { return CLLocation(latitude: latitude, longitude: longitude) }

  // MARK: Initialization

  init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    latitude = unboxer.unbox(Key.latitude)
    longitude = unboxer.unbox(Key.longitude)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    latitude = aDecoder.decodeDoubleForKey(Key.latitude)
    longitude = aDecoder.decodeDoubleForKey(Key.longitude)
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeDouble(latitude, forKey: Key.latitude)
    aCoder.encodeDouble(longitude, forKey: Key.longitude)
  }
}
