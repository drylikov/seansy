import Foundation
import Sugar
import Unbox

final class Cinema: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let id = "_id"
    static let name = "name"
    static let city = "city"
    static let address = "address"
    static let location = "location"
    static let phone = "phone"
    static let photoUrl = "photoUrl"
  }

  // MARK: Inputs

  let id: String
  let name: String
  let city: String
  let address: String?
  let location: Location?
  let phone: String?
  let photoUrl: NSURL?

  // MARK: Private properties

  private let formattedPhone: String -> String = {
    return $0.length == 11 ? "+\($0[0] == "8" ? "7" : $0[0]) (\($0[1..<4])) \($0[4..<7])-\($0[7..<11])" : $0
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    id = unboxer.unbox(Key.id)
    name = unboxer.unbox(Key.name)
    city = unboxer.unbox(Key.city)
    address = unboxer.unbox(Key.address)
    location = unboxer.unbox(Key.location)
    phone = (unboxer.unbox(Key.phone) as String?).flatMap(formattedPhone)
    photoUrl = unboxer.unbox(Key.photoUrl)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    id = aDecoder.decodeObjectForKey(Key.id) as! String
    name = aDecoder.decodeObjectForKey(Key.name) as! String
    city = aDecoder.decodeObjectForKey(Key.city) as! String
    address = aDecoder.decodeObjectForKey(Key.address) as? String
    location = aDecoder.decodeObjectForKey(Key.location) as? Location
    phone = aDecoder.decodeObjectForKey(Key.phone) as? String
    photoUrl = aDecoder.decodeObjectForKey(Key.photoUrl) as? NSURL
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(id, forKey: Key.id)
    aCoder.encodeObject(name, forKey: Key.name)
    aCoder.encodeObject(city, forKey: Key.city)
    aCoder.encodeObject(address, forKey: Key.address)
    aCoder.encodeObject(location, forKey: Key.location)
    aCoder.encodeObject(phone, forKey: Key.phone)
    aCoder.encodeObject(photoUrl, forKey: Key.photoUrl)
  }

  // MARK: Public methods

  func subtitle(locationService locationService: LocationService?) -> String? {
    let subtitleComps = [distanceString(locationService), address].flatMap { $0 }
    return subtitleComps.isEmpty ? nil : subtitleComps.joinWithSeparator(" | ")
  }

  // MARK: Private methods

  private func distanceString(locationService: LocationService?) -> String? {
    return nil
  }
}

// MARK: - Equatable

func == (lhs: Cinema, rhs: Cinema) -> Bool {
  return lhs.id == rhs.id
}
