import Foundation
import Hue
import Unbox

final class MoviePressReview: NSObject, NSCoding, Unboxable {

  // MARK: Public types

  enum ReviewType: String {
    case Positive = "positive", Negative = "negative"
  }

  // MARK: Private types

  private enum Key {
    static let type = "type"
    static let text = "text"
  }

  // MARK: Inputs

  let type: ReviewType
  let text: String

  // MARK: Public properties

  var asset: UIImage.Asset { return type == .Positive ? .LikeIcon : .DislikeIcon }
  var color: UIColor { return type == .Positive ? .hex("#27ae60") : .hex("#c0392c") }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    type = ReviewType(rawValue: unboxer.unbox(Key.type))!
    text = unboxer.unbox(Key.text)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    type = ReviewType(rawValue: aDecoder.decodeObjectForKey(Key.type) as! String)!
    text = aDecoder.decodeObjectForKey(Key.text) as! String
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(type.rawValue, forKey: Key.type)
    aCoder.encodeObject(text, forKey: Key.text)
  }
}
