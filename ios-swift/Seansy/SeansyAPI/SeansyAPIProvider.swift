import Foundation
import JWT
import Moya
import SwiftyUserDefaults

final class SeansyAPIProvider: RxMoyaProvider<Seansy> {
  init(payload: Payload, secret: String) {
    let endpointClosure = { (target: Seansy) -> Endpoint<Seansy> in
      let endpoint = Endpoint<Seansy>(
        URL: target.baseURL.URLByAppendingPathComponent(target.path).absoluteString,
        sampleResponseClosure: { .NetworkResponse(200, target.sampleData) },
        method: target.method,
        parameters: target.parameters
      )
      let authorizationToken =  JWT.encode(payload, algorithm: .HS256(secret))

      return endpoint.endpointByAddingHTTPHeaderFields(["Authorization": authorizationToken])
    }

    super.init(endpointClosure: endpointClosure)
  }
}

// MARK: - TargetType

enum Seansy {
  case Movies, Cinemas, Showtimes(String?)
}

extension Seansy: TargetType {
  var baseURL: NSURL { return NSURL(string: "http://api.seansy.kz")! }
  var path: String {
    switch self {
    case .Movies: return "/movies"
    case .Cinemas: return "/cinemas"
    case .Showtimes(let city): return city.flatMap { "/showtimes/city/\($0)" } ?? "/showtimes"
    }
  }
  var method: Moya.Method {
    return .GET
  }
  var parameters: [String: AnyObject]? {
    return ["limit": 10000]
  }
  var sampleData: NSData {
    switch self {
    case .Movies: return "{\"data\": \"[{}]\"}".dataUsingEncoding(NSUTF8StringEncoding)!
    case .Cinemas: return "{\"data\": \"[{}]\"}".dataUsingEncoding(NSUTF8StringEncoding)!
    case .Showtimes: return "{\"data\": \"[{}]\"}".dataUsingEncoding(NSUTF8StringEncoding)!
    }
  }
}

// MARK: - TargetType Helpers

extension Seansy {

  // MARK: Public properties

  var cachedDataKey: DefaultsKey<NSData?> { return DefaultsKey<NSData?>("\(key).cachedData") }
  var lastUpdateDateKey: DefaultsKey<NSDate?> { return DefaultsKey<NSDate?>("\(key).lastUpdateDate") }

  // MARK: Private properties

  private var key: String {
    switch self {
    case .Movies: return "movies"
    case .Cinemas: return "cinemas"
    case .Showtimes(let city): return city.flatMap { "showtimes.\($0)" } ?? "showtimes"
    }
  }
}
