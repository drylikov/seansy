import Moya
import Unbox

extension Response {
  func mapObject<T: Unboxable>(rootKey: String? = nil) throws -> T {
    let json = try mapJSON()
    guard let dict = (rootKey != nil ? json[rootKey!] : json) as? UnboxableDictionary,
      object: T = try? Unbox(dict) else { throw Error.JSONMapping(self) }

    return object
  }

  func mapArray<T: Unboxable>(rootKey: String? = nil) throws -> [T] {
    let json = try mapJSON()
    guard let dict = (rootKey != nil ? json[rootKey!] : json) as? [UnboxableDictionary],
      objects: [T] = try? Unbox(dict) else { throw Error.JSONMapping(self) }

    return objects
  }
}
