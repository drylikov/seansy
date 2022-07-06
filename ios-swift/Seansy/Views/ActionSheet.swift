import Hue
import Reusable
import Sugar
import Tactile
import UIKit

final class ActionSheetItem {

  // MARK: Inputs

  let title: String?
  let image: UIImage?
  let handler: (() -> Void)?
  let view: UIView?

  // MARK: Public properties

  var selected: Bool = false
  var disabled: Bool = false
  var height: CGFloat { return view.flatMap { $0.height } ?? 50 }

  // MARK: Initialization

  init(title: String? = nil, image: UIImage? = nil, handler: (() -> Void)? = nil, view: UIView? = nil) {
    self.title = title
    self.image = image
    self.handler = handler
    self.view = view
  }
}

// MARK: -

final class ActionSheetCell: UITableViewCell, Reusable {

  // MARK: Private properties

  private lazy var checkImageView: UIImageView = {
    return UIImageView(frame: CGRect(x: self.width - 30, y: (self.height - 20) / 2, width: 20, height: 20)).then {
      $0.optimize()
      $0.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
      $0.tintColor = .whiteColor()
      $0.image = UIImage(.CheckIcon).icon
      $0.hidden = true
    }
  }()
  private var customView: UIView? = nil

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    optimize()
    backgroundColor = .clearColor()
    selectedBackgroundView = UIView().then { $0.backgroundColor = UIColor.blackColor().alpha(0.5) }
    separatorInset = UIEdgeInsetsZero
    layoutMargins = UIEdgeInsetsZero
    preservesSuperviewLayoutMargins = false

    textLabel?.textColor = .whiteColor()
    textLabel?.font = .regularFontOfSize(16)

    imageView?.tintColor = .whiteColor()

    contentView.addSubview(checkImageView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewCell

  override func prepareForReuse() {
    super.prepareForReuse()

    checkImageView.hidden = true
    customView?.removeFromSuperview()
    selectionStyle = .Default
    contentView.alpha = 1.0
  }

  // MARK: Public methods

  func configure(item: ActionSheetItem) {
    if let view = item.view {
      customView = view
      contentView.addSubview(view)
      selectionStyle = .None
    } else {
      if let title = item.title { textLabel?.text = title }
      if let image = item.image { imageView?.image = image.icon }
    }

    if item.selected { checkImageView.hidden = false }
    if item.disabled {
      selectionStyle = .None
      contentView.alpha = 0.3
    }
  }
}

// MARK: -

final class ActionSheet: UIView {

  // MARK: Inputs

  let title: String
  let cancelTitle: String
  var items: [ActionSheetItem]
  let dismissHandler: (() -> Void)?

  // MARK: Private properties

  private var shown = false

  // Views
  private lazy var blurEffect = UIBlurEffect(style: .Dark)
  private lazy var blurView: UIVisualEffectView = {
    return UIVisualEffectView(frame: self.bounds)
  }()
  private lazy var tableView: UITableView = {
    return UITableView(frame: CGRect(size: self.size, edgeInsets: UIEdgeInsets().top(statusBarHeight))).then {
      $0.optimize()
      $0.backgroundColor = .clearColor()
      $0.separatorInset = UIEdgeInsetsZero
      $0.separatorColor = UIColor.whiteColor().alpha(0.25)
      $0.tableHeaderView = self.titleLabel
      $0.tableFooterView = self.cancelButton
      $0.showsVerticalScrollIndicator = false
      $0.alwaysBounceVertical = true
      $0.dataSource = self
      $0.registerReusableCell(ActionSheetCell)
    }
  }()
  private lazy var titleLabel: UILabel = {
    return UILabel(frame: CGRect(x: 15, y: 0, width: self.width - 30, height: 0)).then {
      $0.optimize()
      $0.text = self.title
      $0.textColor = .whiteColor()
      $0.font = .lightFontOfSize(22)
      $0.textAlignment = .Center
      $0.sizeToFitInHeight(0)
      $0.height += 30
      let hairlineView = UIView(frame: CGRect(x: 0, y: $0.height - 1 / UIScreen.mainScreen().scale,
        width: self.width, height: 1 / UIScreen.mainScreen().scale))
        .then { $0.backgroundColor = UIColor.whiteColor().alpha(0.25) }
      $0.addSubview(hairlineView)
    }
  }()
  private lazy var cancelButton: UIButton = {
    return UIButton(frame: CGRect(width: self.width, height: 50)).then {
      $0.optimize()
      $0.titleLabel?.textColor = .whiteColor()
      $0.titleLabel?.font = .regularFontOfSize(16)
      $0.setTitle(self.cancelTitle, forState: .Normal)
      $0.on(.TouchUpInside) { _ in self.dismiss() }
      let hairlineView = UIView(frame: CGRect(width: self.width, height: 1 / UIScreen.mainScreen().scale))
        .then { $0.backgroundColor = UIColor.whiteColor().alpha(0.25) }
      $0.addSubview(hairlineView)
    }
  }()

  // MARK: Initialization

  init(title: String, cancelTitle: String = "Назад", items: [ActionSheetItem] = [],
    dismissHandler: (() -> Void)? = nil) {
      self.title = title
      self.cancelTitle = cancelTitle
      self.items = items
      self.dismissHandler = dismissHandler

      super.init(frame: screenBounds)

      blurView.contentView.addSubview(tableView)
      addSubview(blurView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func addItem(item: ActionSheetItem) {
    items.append(item)
  }

  func show(duration duration: NSTimeInterval = 0.3, completion: (() -> Void)? = nil) {
    if shown { return } else { shown = true }

    tableView.delegate = self
    tableView.userInteractionEnabled = true
    tableView.contentSize.height = items.reduce(titleLabel.bottom + cancelButton.height) { $0 + $1.height }
    if tableView.contentSize.height < tableView.height * (1 - 0.2) {
      tableView.contentInset = UIEdgeInsets(top: tableView.height - tableView.contentSize.height, left: 0,
        bottom: 0, right: 0)
    } else {
      tableView.contentInset = UIEdgeInsets(top: tableView.height * 0.2, left: 0, bottom: 0, right: 0)
    }

    blurView.effect = nil
    tableView.transform = CGAffineTransformMakeTranslation(0, tableView.contentSize.height)
    UIView.animateWithDuration(duration,
      animations: {
        self.blurView.effect = self.blurEffect
        self.tableView.transform = CGAffineTransformIdentity
      },
      completion: { _ in completion?() })
  }

  func dismiss(duration duration: NSTimeInterval = 0.3, completion: (() -> Void)? = nil) {
    if !shown { return } else { shown = false }

    tableView.delegate = nil
    tableView.userInteractionEnabled = false
    tableView.contentInset.top -= tableView.contentOffset.y

    UIView.animateWithDuration(duration,
      animations: {
        self.blurView.effect = nil
        self.tableView.transform = CGAffineTransformMakeTranslation(0, self.tableView.contentSize.height)
      },
      completion: { _ in
        self.removeFromSuperview()
        completion?()
        self.dismissHandler?()
    })
  }
}

// MARK: - UITableViewDataSource

extension ActionSheet: UITableViewDataSource {
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return tableView
      .dequeueReusableCell(indexPath: indexPath, cellType: ActionSheetCell.self)
      .then { $0.configure(items[indexPath.row]) }
  }
}

// MARK: - UITableViewDelegate

extension ActionSheet: UITableViewDelegate {
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return items[indexPath.row].height
  }

  func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    let item = items[indexPath.row]
    return item.view != nil || item.disabled ? nil : indexPath
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    items.forEach { $0.selected = false }

    let item = items[indexPath.row]
    item.selected = true
    tableView.reloadData()

    dismiss(completion: item.handler)
  }
}

// MARK: - UIScrollViewDelegate

extension ActionSheet {
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    let velocity = scrollView.panGestureRecognizer.velocityInView(self)

    if velocity.y > 2000 && scrollView.contentOffset.y < -scrollView.contentInset.top - 20 {
      dismiss(duration: 0.2)
    } else if scrollView.contentOffset.y < -scrollView.contentInset.top - 80 {
      dismiss()
    }
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

  func presentActionSheet(actionSheet: ActionSheet) {
    targetView.addSubview(actionSheet)
    actionSheet.show()
  }
}
