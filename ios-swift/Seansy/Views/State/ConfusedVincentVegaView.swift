import Gifu
import SteviaLayout
import Sugar
import UIKit

class ConfusedVincentVegaView: UIView {

  // MARK: Public properties

  let titleLabel = UILabel().then {
    $0.optimize()
    $0.textColor = .whiteColor()
    $0.textAlignment = .Center
    $0.font = .regularFontOfSize(18)
    $0.numberOfLines = 0
  }
  let gifView = AnimatableImageView()

  // MARK: Initialization

  init(frame: CGRect, title: String) {
    super.init(frame: frame)

    optimize()
    sv(titleLabel, gifView)
    titleLabel.text = title
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UIView

  override func willMoveToSuperview(newSuperview: UIView?) {
    if newSuperview != nil { gifView.animateWithImage(named: "ConfusedVincentVega.gif") }
  }

  override func removeFromSuperview() {
    super.removeFromSuperview()
    gifView.stopAnimatingGIF()
  }
}
