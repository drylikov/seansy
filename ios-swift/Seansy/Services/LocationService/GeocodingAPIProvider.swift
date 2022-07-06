import CoreLocation
import Foundation
import Moya
import RxSwift
import Unbox

final class GeocodingAPIProvider: RxMoyaProvider<Geocode> {
  init() {
    super.init(endpointClosure: { (target: Geocode) -> Endpoint<Geocode> in
      return Endpoint<Geocode>(
        URL: target.baseURL.URLByAppendingPathComponent(target.path).absoluteString,
        sampleResponseClosure: { .NetworkResponse(200, target.sampleData) },
        method: target.method,
        parameters: target.parameters
      )
    })
  }
}

// MARK: - TargetType

enum Geocode {
  case Coordinate(CLLocationCoordinate2D)
  case Address(String)
}

extension Geocode: TargetType {
  var baseURL: NSURL { return NSURL(string: "https://maps.googleapis.com/maps/api/geocode")! }
  var path: String { return "/json" }
  var method: Moya.Method { return .GET }
  var parameters: [String: AnyObject]? {
    switch self {
    case .Coordinate(let coordinate):
      return ["latlng": "\(coordinate.latitude),\(coordinate.longitude)", "language": "ru"]
    case .Address(let address):
      return ["address": "\(address)", "region": "kz", "language": "ru"]
    }
  }
  var sampleData: NSData {
    return "{\"results\": \"[]\",\"status\":\"ZERO_RESULTS\"}".dataUsingEncoding(NSUTF8StringEncoding)!
  }
}

// MARK: - Observable Extension

extension ObservableType where E == Response {
  func mapGeocodingResults() -> Observable<Address> {
    return observeOn(SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
      .flatMap { Observable.just(try $0.mapGeocodingResults()) }
      .observeOn(MainScheduler.instance)
  }
}

// MARK: - Response Extension

enum GeocodingStatus: String {
  case OK = "OK"
  case ZeroResults = "ZERO_RESULTS"
  case APILimit = "OVER_QUERY_LIMIT"
  case RequestDenied = "REQUEST_DENIED"
  case InvalidRequest = "INVALID_REQUEST"
  case UnknownError =  "UNKNOWN_ERROR"
}

enum GeocodingError: ErrorType {
  case Status(GeocodingStatus)
}

extension Response {
  func mapGeocodingResults() throws -> Address {
    let json = try mapJSON()
    guard let status = GeocodingStatus(rawValue: json["status"]!! as! String),
      results = json["results"]!! as? [UnboxableDictionary] else { throw Error.JSONMapping(self) }
    if status != .OK { throw GeocodingError.Status(status) }

    guard let result = results.first, address: Address = try? Unbox(result) else { throw Error.JSONMapping(self) }

    return address
  }
}
