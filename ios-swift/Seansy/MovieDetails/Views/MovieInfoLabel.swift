import UIKit
import Sugar

final class MovieInfoLabel: UILabel {
  override init(frame: CGRect) {
    super.init(frame: frame)

    shadowColor = UIColor.blackColor().alpha(0.5)
    shadowOffset = CGSize(width: 1, height: 1)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
