import Hue
import Popover
import Reusable
import UIKit

struct PopoverMenuItem {

  // MARK: Inputs

  let title: String
  let image: UIImage
  let handler: () -> Void

  // MARK: Public properties

  var height: CGFloat { return 50 }
}

// MARK: -

final class PopoverMenuCell: UITableViewCell, Reusable {

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    optimize()
    selectionStyle = .None
    backgroundColor = .clearColor()
    selectedBackgroundView = UIView().then { $0.backgroundColor = UIColor.blackColor().alpha(0.5) }
    separatorInset = UIEdgeInsetsZero
    layoutMargins = UIEdgeInsetsZero
    preservesSuperviewLayoutMargins = false

    textLabel?.textColor = .primaryColor()
    textLabel?.font = .regularFontOfSize(16)

    imageView?.tintColor = .primaryColor()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func configure(title title: String, image: UIImage) {
    textLabel!.text = title
    imageView!.image = image.icon
  }
}

// MARK: -

final class PopoverMenu: UITableView {

  // MARK: Inputs

  let items: [PopoverMenuItem]
  let popover: Popover

  // MARK: Initialization

  init(frame: CGRect, items: [PopoverMenuItem], popover: Popover) {
    self.items = items
    self.popover = popover
    super.init(frame: frame, style: .Plain)

    optimize()
    backgroundColor = .clearColor()
    separatorInset = UIEdgeInsetsZero
    separatorColor = UIColor.primaryColor().alpha(0.25)
    bounces = false
    tableFooterView = UIView()
    dataSource = self
    delegate = self
    registerReusableCell(PopoverMenuCell)
    height = items.map { $0.height }.reduce(0, combine: +)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - UITableViewDataSource

extension PopoverMenu: UITableViewDataSource {
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return tableView.dequeueReusableCell(indexPath: indexPath, cellType: PopoverMenuCell.self).then {
      let item = items[indexPath.row]
      $0.configure(title: item.title, image: item.image)
      $0.separatorInset.right = indexPath.row == items.count - 1 ? tableView.width : 0
    }
  }
}

// MARK: - UITableViewDelegate

extension PopoverMenu: UITableViewDelegate {
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return items[indexPath.row].height
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    popover.dismiss()
    items[indexPath.row].handler()
  }
}
