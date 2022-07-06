import Reusable
import Sugar
import UIKit

final class ListSectionHeaderView: UITableViewHeaderFooterView, Reusable {

  // MARK: Public properties

  static let height: CGFloat = 40

  // MARK: Private properties

  private lazy var titleLabel: UILabel = {
    return UILabel(frame: CGRect(x: 15, y: 0, width: screenWidth - 30, height: ListSectionHeaderView.height)).then {
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .semiboldFontOfSize(12)
    }
  }()

  // MARK: Initialization

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)

    backgroundView = UIView().then { $0.backgroundColor = .primaryColor() + UIColor.blackColor().alpha(0.25) }
    contentView.addSubview(titleLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewHeaderFooterView

  override func prepareForReuse() {
    titleLabel.text = nil
  }

  // MARK: Public methods

  func configure(title: String) {
    titleLabel.text = title.uppercaseString
  }
}
