import Foundation
import Moya

final class IPAPIProvider: RxMoyaProvider<Geolocate> {
  init() {
    super.init(endpointClosure: { (target: Geolocate) -> Endpoint<Geolocate> in
      return Endpoint<Geolocate>(
        URL: target.baseURL.URLByAppendingPathComponent(target.path).absoluteString,
        sampleResponseClosure: { .NetworkResponse(200, target.sampleData) },
        method: target.method,
        parameters: target.parameters
      )
    })
  }
}

// MARK: - TargetType

struct Geolocate: TargetType {
  var baseURL: NSURL { return NSURL(string: "https://geoip.nekudo.com")! }
  var path: String { return "/api" }
  var method: Moya.Method { return .GET }
  var parameters: [String: AnyObject]? { return nil }
  var sampleData: NSData { return "{}".dataUsingEncoding(NSUTF8StringEncoding)! }
}
