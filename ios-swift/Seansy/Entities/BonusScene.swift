import Foundation
import Unbox

final class BonusScene: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let afterCredits = "afterCredits"
    static let duringCredits = "duringCredits"
  }

  // MARK: Inputs

  let afterCredits: Bool?
  let duringCredits: Bool?

  // MARK: Public properties

  var string: String? {
    switch self {
    case afterCredits != nil && duringCredits != nil:
      return "Бонусные сцены во время и после титров"
    case afterCredits != nil:
      return "Бонусная сцена после титров"
    case duringCredits != nil:
      return "Бонусная сцена во время титров"
    default: return nil
    }
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    afterCredits = unboxer.unbox(Key.afterCredits)
    duringCredits = unboxer.unbox(Key.duringCredits)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    afterCredits = aDecoder.decodeObjectForKey(Key.afterCredits) as? Bool
    duringCredits = aDecoder.decodeObjectForKey(Key.duringCredits) as? Bool
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(afterCredits, forKey: Key.afterCredits)
    aCoder.encodeObject(duringCredits, forKey: Key.duringCredits)
  }
}
