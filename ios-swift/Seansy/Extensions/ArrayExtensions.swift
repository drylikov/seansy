import Foundation

extension SequenceType {
  func groupedBy<U: Hashable>(@noescape keyFunc: Generator.Element -> U) -> [U: [Generator.Element]] {
    var dict: [U: [Generator.Element]] = [:]
    for el in self {
      let key = keyFunc(el)
      if case nil = dict[key]?.append(el) { dict[key] = [el] }
    }

    return dict
  }
}

extension CollectionType {
  func find(@noescape predicate: (Generator.Element) throws -> Bool) rethrows -> Generator.Element? {
    return try indexOf(predicate).map { self[$0] }
  }
}

extension MutableCollectionType where Self.Index == Int {
  func shuffle() -> Self {
    var r = self
    for i in 0..<(count - 1) {
      let j = Int(arc4random_uniform(UInt32(count - i))) + i
      swap(&r[i], &r[j])
    }
    return r
  }
}

extension Array {
  func limit(maxCount: Int) -> [Element] {
    return Array(self[0..<min(count, maxCount)])
  }
}

extension Array where Element: Hashable {
  var unique: [Element] {
    return Array(Set(self))
  }
}
