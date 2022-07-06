import Hue
import RxCocoa
import RxSwift
import Sugar
import Toucan
import UIKit

final class BackdropColors: NSObject, NSCoding {

  // MARK: Public types

  enum ColorType {
    case Background, Text
  }

  // MARK: Private types

  private enum Key {
    static let backgroundColor = "backgroundColor"
    static let textColor = "textColor"
  }

  // MARK: Public constants

  static let defaultBackgroundColor = UIColor.blackColor()
  static let defaultTextColor = UIColor.whiteColor().alpha(0.75)

  // MARK: Public subscripts

  subscript(type: ColorType) -> UIColor {
    switch type {
    case .Background: return backgroundColor
    case .Text: return textColor
    }
  }

  // MARK: Private properties

  private var backgroundColor: UIColor
  private var textColor: UIColor

  // MARK: Initialization

  init(backgroundColor: UIColor, textColor: UIColor) {
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    super.init()
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    backgroundColor = aDecoder.decodeObjectForKey(Key.backgroundColor) as! UIColor
    textColor = aDecoder.decodeObjectForKey(Key.textColor) as! UIColor
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(backgroundColor, forKey: Key.backgroundColor)
    aCoder.encodeObject(textColor, forKey: Key.textColor)
  }

  // MARK: Public methods

  static func defaultColors() -> BackdropColors {
    return BackdropColors(
      backgroundColor: BackdropColors.defaultBackgroundColor,
      textColor: BackdropColors.defaultTextColor
    )
  }

  static func getColors(image: UIImage?) -> Driver<BackdropColors> {
    guard let image = image else { return Driver.just(.defaultColors()) }

    return Observable
      .create { observer in
        dispatch(queue: .Background) {
          let colorCube = CCColorCube()

          var backgroundColor = BackdropColors.defaultBackgroundColor
          var textColor = BackdropColors.defaultTextColor

          let dominantColors = colorCube
            .extractColorsFromImage(image, flags: CCAvoidWhite.rawValue)
            .map { $0 as! UIColor }
          if let index = dominantColors.indexOf({ $0.isContrastingWith(.whiteColor()) }) {
            backgroundColor = dominantColors[index]
          } else {
            backgroundColor = image
              .averageColorInRect(CGRect(size: image.size, edgeInsets: UIEdgeInsets().top(image.size.height * 0.9)))
          }

          let brightColors = colorCube
            .extractColorsFromImage(image,
              flags: CCOnlyDistinctColors.rawValue | CCOrderByBrightness.rawValue |
                CCOnlyBrightColors.rawValue | CCAvoidWhite.rawValue
            )
            .map { $0 as! UIColor }
          if let index = brightColors.indexOf({ !$0.isDark && $0.isContrastingWith(backgroundColor) }) {
            textColor = brightColors[index]
          }

          observer.onNext(BackdropColors(backgroundColor: backgroundColor, textColor: textColor))
          observer.onCompleted()
        }

        return NopDisposable.instance
      }
      .asDriver(onErrorJustReturn: .defaultColors())
  }
}
