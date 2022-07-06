import Foundation
import Unbox

final class Trailer: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let youtubeId = "youtubeId"
  }

  // MARK: Inputs

  let youtubeId: String

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    youtubeId = unboxer.unbox(Key.youtubeId)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    youtubeId = aDecoder.decodeObjectForKey(Key.youtubeId) as! String
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(youtubeId, forKey: Key.youtubeId)
  }
}
