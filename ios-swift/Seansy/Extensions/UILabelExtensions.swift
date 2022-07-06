import UIKit
import Sugar

extension UILabel {
  func adjustFontSize(maxLines: UInt, minSize: CGFloat) {
    guard let text = text else { return }

    while overflows {
      font = font.fontWithSize(font.pointSize - 1)
    }
    while sizeThatFitsInHeight(0).height > text.size(font).height * CGFloat(maxLines) {
      font = font.fontWithSize(font.pointSize - 1)
    }

    numberOfLines = 0
    height = text.size(font, size: CGSize(width: width, height: 0)).height
  }

  func sizeToFitInHeight(height: CGFloat) {
    if text == nil { return }

    numberOfLines = 0
    self.height = sizeThatFitsInHeight(height).height
  }

  func sizeThatFitsInHeight(height: CGFloat) -> CGSize {
    guard let text = text else { return size }
    return text.size(font, size: CGSize(width: width, height: height))
  }

  private var overflows: Bool {
    guard let text = text else { return false }

    let words = text.componentsSeparatedByString(" ")
    return words.indexOf { word in
      return (word == words.last ? word + " " : word).size(font).width >= width
    } != nil
  }
}
