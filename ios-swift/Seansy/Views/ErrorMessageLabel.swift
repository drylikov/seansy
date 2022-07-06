import UIKit

final class ErrorMessageLabel: UILabel {
  init() {
    super.init(frame: .zero)

    backgroundColor = .flatRedColor()
    textColor = .whiteColor()
    textAlignment = .Center
    font = .regularFontOfSize(13)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
