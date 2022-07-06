import UIKit

final class SettingsViewController: UIViewController {

  // MARK: Private properties

  private lazy var tableView: UITableView = {
    return UITableView(frame: .zero, style: .Grouped).then {
      $0.optimize()
      $0.backgroundColor = .clearColor()
      $0.separatorStyle = .None
      $0.allowsSelection = false
    }
  }()

  // MARK: Initialization

  init() {
    super.init(nibName: nil, bundle: nil)

    title = "Настройки"
    tabBarItem.image = UIImage(.SettingsIconOutline)
    tabBarItem.selectedImage = UIImage(.SettingsIconFill)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
