import Reusable
import UIKit

final class SwitchTableViewCell: UITableViewCell, Reusable {

  // MARK: Private properties

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  required init?(coder aDecoder: NSCoder) {
     fatalError("init(coder:) has not been implemented")
  }
}
