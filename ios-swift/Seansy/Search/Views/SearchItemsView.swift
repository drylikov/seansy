import Reusable
import RxDataSources
import UIKit

struct SearchItemsSection: SectionModelType {
  typealias Item = SearchItem
  let items: [SearchItem]
}

// MARK: -

final class SearchItemsCell: UITableViewCell, Reusable {

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)

    backgroundColor = .clearColor()
    selectedBackgroundView = UIView().then { $0.backgroundColor = UIColor.blackColor().alpha(0.5) }

    textLabel?.textColor = .whiteColor()
    textLabel?.font = .regularFontOfSize(16)
    textLabel?.lineBreakMode = .ByTruncatingMiddle

    detailTextLabel?.textColor = BackdropColors.defaultTextColor
    detailTextLabel?.font = .regularFontOfSize(12)

    imageView?.contentMode = .Center
    imageView?.tintColor = .accentColor()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func configure(item: SearchItem) {
    textLabel?.text = item.query
    detailTextLabel?.text = item.subtitle
    imageView?.image = UIImage(item.smallAsset).icon
  }
}

// MARK: -

final class SearchItemsView: UITableView {

  // MARK: Public properties

  let sectionedDataSource = RxTableViewSectionedReloadDataSource<SearchItemsSection>()

  // MARK: Initialization

  init() {
    super.init(frame: .zero, style: .Plain)

    optimize()
    backgroundColor = .clearColor()
    separatorStyle = .None
    registerReusableCell(SearchItemsCell)
    sectionedDataSource.configureCell = { _, tableView, indexPath, item in
      return tableView
        .dequeueReusableCell(indexPath: indexPath, cellType: SearchItemsCell.self)
        .then { $0.configure(item) }
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
