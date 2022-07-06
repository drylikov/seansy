import Foundation
import Unbox

private struct AddressComponent: Unboxable {

  // MARK: Inputs

  let longName: String
  let shortName: String
  let types: [String]

  // MARK: Initialization

  init(unboxer: Unboxer) {
    longName = unboxer.unbox("long_name")
    shortName = unboxer.unbox("short_name")
    types = unboxer.unbox("types")
  }
}

// MARK: - AddressComponent Array Extension

extension CollectionType where Generator.Element == AddressComponent {
  func component(type: String) -> Generator.Element? {
    return indexOf({ $0.types.contains(type) }).flatMap { self[$0] }
  }
}

// MARK: -

final class Address: Unboxable {

  // MARK: Inputs

  let location: Location?
  let city: City?

  // MARK: Initialization

  init() {
    self.location = nil
    self.city = nil
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    if let addressComponents: [AddressComponent] = unboxer.unbox("address_components") {
      location = unboxer.unbox("geometry.location", isKeyPath: true)
      city = addressComponents.component("locality")?.longName
    } else {
      location = nil
      city = unboxer.unbox("city")
    }
  }
}

// MARK: - CustomStringConvertible

extension Address: CustomStringConvertible {
  var description: String {
    return "location: \(location), city: \(city)"
  }
}
