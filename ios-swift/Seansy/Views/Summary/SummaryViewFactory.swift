import Sugar
import UIKit

class SummaryViewFactory: NSObject {

  // MARK: Inputs

  let bounds: CGRect

  // MARK: Public properties

  let imageView = GradientImageView().then { $0.clipsToBounds = true }
  var subviews: [UIView] { return [] }

  // MARK: Initialization

  init(bounds: CGRect) {
    self.bounds = bounds
    super.init()
  }

  // MARK: Public methods

  func prepareForReuse() {
    imageView.image = nil
  }
}
