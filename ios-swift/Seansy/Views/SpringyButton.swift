import Cheetah
import Tactile
import UIKit

class SpringyButton: UIButton {
  override init(frame: CGRect) {
    super.init(frame: frame)

    adjustsImageWhenHighlighted = false

    on([.TouchDown, .TouchDragEnter], { _ in self.cheetah.remove().scale(0.95).run() })
    on(.TouchUpInside, { _ in self.cheetah.remove().scale(1.0).spring().run() })
    on(.TouchDragExit, { _ in self.cheetah.remove().scale(1.0).run() })
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
