import Hue
import Reusable
import Sugar
import Tactile
import UIKit

final class DropdownMenuItem {

  // MARK: Inputs

  let title: String
  let handler: (() -> Void)?

  // MARK: Public properties

  var selected: Bool = false
  var disabled: Bool = false
  var height: CGFloat { return 50 }

  // MARK: Initialization

  init(title: String, handler: (() -> Void)? = nil) {
    self.title = title
    self.handler = handler
  }
}

// MARK: -

final class DropdownMenuCell: UITableViewCell, Reusable {

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    optimize()
    backgroundColor = .primaryColor()
    selectedBackgroundView = UIView().then { $0.backgroundColor = UIColor.blackColor().alpha(0.5) }
    separatorInset = UIEdgeInsetsZero
    layoutMargins = UIEdgeInsetsZero
    preservesSuperviewLayoutMargins = false

    textLabel?.textColor = .whiteColor()
    textLabel?.font = .regularFontOfSize(16)
    textLabel?.textAlignment = .Center
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewCell

  override func prepareForReuse() {
    super.prepareForReuse()

    backgroundColor = .primaryColor()
    textLabel?.textColor = .whiteColor()
    selectionStyle = .Default
    contentView.alpha = 1.0
  }

  // MARK: Public methods

  func configure(item: DropdownMenuItem) {
    textLabel?.text = item.title

    if item.selected {
      backgroundColor = .accentColor()
      textLabel?.textColor = .primaryColor()
      selectionStyle = .None
    }
    if item.disabled {
      selectionStyle = .None
      contentView.alpha = 0.3
    }
  }
}

// MARK: -

final class DropdownMenu: UIView {

  // MARK: Inputs

  let dismissHandler: (() -> Void)?

  // MARK: Private properties

  private let navigationController: UINavigationController
  private var items: [DropdownMenuItem]

  // MARK: Private properties

  private var shown = false

  // Views
  private lazy var tableView: UITableView = {
    return UITableView(frame: self.bounds).then {
      $0.optimize()
      $0.backgroundColor = .clearColor()
      $0.showsVerticalScrollIndicator = false
      $0.bounces = false
      $0.separatorInset = UIEdgeInsetsZero
      $0.separatorColor = UIColor.whiteColor().alpha(0.25)
      $0.tableFooterView = UIView()
      $0.dataSource = self
      $0.registerReusableCell(DropdownMenuCell)
      $0.on(UITapGestureRecognizer().then { $0.delegate = self }) { _ in self.dismiss() }
    }
  }()
  private lazy var backgroundView: UIView = {
    return UIView(frame: self.bounds).then { $0.backgroundColor = UIColor.blackColor().alpha(0.25) }
  }()

  // MARK: Initialization

  init(navigationController: UINavigationController, items: [DropdownMenuItem], dismissHandler: (() -> Void)? = nil) {
    self.navigationController = navigationController
    self.items = items
    self.dismissHandler = dismissHandler
    let headerHeight = navigationController.navigationBar.height + statusBarHeight + 1 / UIScreen.mainScreen().scale
    super.init(frame: CGRect(x: 0, y: headerHeight, width: screenWidth, height: screenHeight - headerHeight))

    clipsToBounds = true

    addSubview(backgroundView)
    addSubview(tableView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func addItem(item: DropdownMenuItem) {
    items.append(item)
  }

  func show(duration duration: NSTimeInterval = 0.3, completion: (() -> Void)? = nil) {
    if shown { return } else { shown = true }

    tableView.delegate = self
    tableView.userInteractionEnabled = true
    tableView.contentInset.top = 0
    tableView.contentSize.height = items.reduce(0) { $0 + $1.height }

    backgroundView.alpha = 0
    tableView.transform = CGAffineTransformMakeTranslation(0, -tableView.contentSize.height)
    UIView.animateWithDuration(duration,
      animations: {
        self.backgroundView.alpha = 1
        self.tableView.transform = CGAffineTransformIdentity
      },
      completion: { _ in completion?()
    })
  }

  func dismiss(duration duration: NSTimeInterval = 0.3, completion: (() -> Void)? = nil) {
    if !shown { return } else { shown = false }

    tableView.delegate = nil
    tableView.userInteractionEnabled = false
    tableView.contentInset.top -= tableView.contentOffset.y

    UIView.animateWithDuration(duration,
      animations: {
        self.backgroundView.alpha = 0
        self.tableView.transform = CGAffineTransformMakeTranslation(0, -self.tableView.contentSize.height)
      },
      completion: { _ in
        self.removeFromSuperview()
        completion?()
        self.dismissHandler?()
    })
  }
}

// MARK: - UITableViewDataSource

extension DropdownMenu: UITableViewDataSource {
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return tableView
      .dequeueReusableCell(indexPath: indexPath, cellType: DropdownMenuCell.self).then {
      $0.configure(items[indexPath.row])
      $0.separatorInset.right = indexPath.row == items.count - 1 ? tableView.width : 0
    }
  }
}

// MARK: - UITableViewDelegate

extension DropdownMenu: UITableViewDelegate {
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return items[indexPath.row].height
  }

  func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    return items[indexPath.row].disabled ? nil : indexPath
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    dismiss(completion: items[indexPath.row].handler)
  }
}

// MARK: - UIGestureRecognizerDelegate

extension DropdownMenu: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    return tableView.indexPathForRowAtPoint(touch.locationInView(tableView)) == nil
  }
}

// MARK: - UIViewController Helper

extension UIViewController {
  private var targetView: UIView {
    var viewController = self
    while let parentViewController = viewController.parentViewController {
      viewController = parentViewController
    }
    return viewController.view
  }

  func presentDropdownMenu(dropdownMenu: DropdownMenu) {
    targetView.addSubview(dropdownMenu)
    dropdownMenu.show()
  }
}
