import Foundation
import Unbox

final class ShowtimePrices: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let adult = "adult"
    static let children = "children"
    static let student = "student"
    static let vip = "vip"
  }

  // MARK: Inputs

  let adult: Int?
  let children: Int?
  let student: Int?
  let vip: Int?

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    adult = unboxer.unbox(Key.adult)
    children = unboxer.unbox(Key.children)
    student = unboxer.unbox(Key.student)
    vip = unboxer.unbox(Key.vip)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    adult = aDecoder.decodeObjectForKey(Key.adult) as? Int
    children = aDecoder.decodeObjectForKey(Key.children) as? Int
    student = aDecoder.decodeObjectForKey(Key.student) as? Int
    vip = aDecoder.decodeObjectForKey(Key.vip) as? Int
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(adult, forKey: Key.adult)
    aCoder.encodeObject(children, forKey: Key.children)
    aCoder.encodeObject(student, forKey: Key.student)
    aCoder.encodeObject(vip, forKey: Key.vip)
  }
}
