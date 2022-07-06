import Sugar
import UIKit

final class ScrollingNavigationBarTitleView: UIView {

  // MARK: Private properties

  private let textLabel = UILabel().then {
    $0.optimize()
    $0.textColor = .whiteColor()
    $0.textAlignment = .Center
    $0.font = .regularFontOfSize(17)
  }

  // MARK: Initialization

  init(title: String) {
    super.init(frame: .zero)

    optimize()
    clipsToBounds = true
    textLabel.text = title
    textLabel.sizeToFit()
    size = textLabel.size
    addSubview(textLabel)

    setProgress(0)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UIView

  override func layoutSubviews() {
    textLabel.width = min(textLabel.width, width)
  }

  // MARK: Public methods

  func setProgress(progress: CGFloat) {
    textLabel.top = textLabel.height * (1 - progress)
  }
}
