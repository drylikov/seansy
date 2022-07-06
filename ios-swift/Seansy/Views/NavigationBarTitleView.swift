import Hue
import Sugar
import UIKit

final class NavigationBarTitleView: UIView {

  // MARK: Public properties

  var loading = false {
    didSet {
      if !loading {
        activityIndicatorView.stopAnimating()
      } else {
        activityIndicatorView.startAnimating()
      }
      [cityLabel, dateLabel, arrowIconView].forEach { $0.hidden = loading }

      updateView()
    }
  }
  var city = "" {
    didSet {
      cityLabel.text = city
      cityLabel.sizeToFit()
      dateLabel.centerX = cityLabel.centerX
      dateLabel.top = cityLabel.bottom

      updateView()
    }
  }
  var dateIndex = 0 {
    didSet {
      switch dateIndex {
      case 0: dateLabel.text = nil
      case 1: dateLabel.text = "завтра"
      case 2: dateLabel.text = "послезавтра"
      default: break
      }
      dateLabel.sizeToFit()

      updateView()
    }
  }

  // MARK: Private properties

  private lazy var activityIndicatorView: UIActivityIndicatorView = {
    return UIActivityIndicatorView(activityIndicatorStyle: .White)
  }()
  private lazy var cityLabel: UILabel = {
    return UILabel().then {
      $0.optimize()
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(17)
    }
  }()
  private lazy var dateLabel: UILabel = {
    return UILabel().then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .regularFontOfSize(13)
    }
  }()
  private(set) lazy var arrowIconView: ArrowIconView = {
    return ArrowIconView(frame: CGRect(width: 14, height: 1), orientation: .Horizontal)
      .then { $0.point(.Down, animated: true) }
  }()

  // MARK: Initialization

  init() {
    super.init(frame: .zero)
    [cityLabel, dateLabel, arrowIconView, activityIndicatorView].forEach { addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Private methods

  private func updateView() {
    if loading {
      size = activityIndicatorView.size
    } else {
      arrowIconView.left = max(cityLabel.right, dateLabel.right) + 10
      arrowIconView.centerY = dateLabel.bottom / 2

      width = arrowIconView.right
      height = dateLabel.bottom
    }
  }
}
