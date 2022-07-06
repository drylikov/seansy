import Foundation

extension Dictionary {
  func map<V>(transform: (Key, Value) -> V) -> [Key: V] {
    var results = [Key: V]()
    keys.forEach { results.updateValue(transform($0, self[$0]!), forKey: $0) }
    return results
  }
}
