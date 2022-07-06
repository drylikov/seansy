import SteviaLayout
import Sugar
import UIKit

final class LoadingView: UIView {

  // MARK: Private properties

  private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    optimize()
    sv(activityIndicatorView)
    activityIndicatorView.centerInContainer()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UIView

  override func willMoveToSuperview(newSuperview: UIView?) {
    if newSuperview != nil { activityIndicatorView.startAnimating() }
  }

  override func removeFromSuperview() {
    super.removeFromSuperview()
    activityIndicatorView.stopAnimating()
  }
}
