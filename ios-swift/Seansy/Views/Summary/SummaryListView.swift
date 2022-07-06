import Sugar
import UIKit

class SummaryListView: UITableView {
  init() {
    super.init(frame: .zero, style: .Plain)

    optimize()
    backgroundColor = .clearColor()
    indicatorStyle = .White
    separatorStyle = .None
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
