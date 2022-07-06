import Reusable
import RxDataSources
import Sugar
import UIKit

struct CustomViewWrapperSection: SectionModelType {
  typealias Item = UIView
  let items: [UIView]
}

// MARK: -

final class CustomViewCell: UITableViewCell, Reusable {

  // MARK: Private properties

  private var customView: UIView? {
    willSet { customView?.removeFromSuperview() }
  }

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    optimize()
    backgroundColor = .clearColor()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewCell

  override func prepareForReuse() {
    super.prepareForReuse()
    customView = nil
  }

  // MARK: Public methods

  func configure(customView: UIView) {
    self.customView = customView
    contentView.addSubview(customView)
  }
}

// MARK: -

final class CustomViewWrapperTableView: UITableView {

  // MARK: Public properties

  let sectionedDataSource = RxTableViewSectionedReloadDataSource<CustomViewWrapperSection>()

  // MARK: Initialization

  init() {
    super.init(frame: .zero, style: .Plain)

    optimize()
    backgroundColor = .clearColor()
    separatorStyle = .None
    allowsSelection = false
    registerReusableCell(CustomViewCell)
    sectionedDataSource.configureCell = { _, tableView, indexPath, view in
      return tableView
        .dequeueReusableCell(indexPath: indexPath, cellType: CustomViewCell.self)
        .then { $0.configure(view) }
    }
    dataSource = sectionedDataSource
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
