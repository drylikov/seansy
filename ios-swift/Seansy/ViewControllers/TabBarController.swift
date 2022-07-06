import UIKit

final class TabBarController: UITabBarController {

  // MARK: Inputs

  let dataManager: DataManager

  // MARK: Public properties

  lazy var navigationControllers: [NavigationController] = {
    return [self.movieListVC, self.showtimeListVC, self.cinemaListVC, self.settingsVC]
      .map { NavigationController(rootViewController: $0) }
  }()

  // MARK: Private properties

  // View controllers
  private lazy var movieListVC: MovieListViewController = {
    return MovieListViewController.new(self.dataManager)
  }()
  private lazy var showtimeListVC: ShowtimeListViewController = {
    return ShowtimeListViewController.new(self.dataManager)
  }()
  private lazy var cinemaListVC: CinemaListViewController = {
    return CinemaListViewController.new(self.dataManager)
  }()
  private lazy var settingsVC = SettingsViewController()

  // MARK: Initialization

  init(dataManager: DataManager) {
    self.dataManager = dataManager
    super.init(nibName: nil, bundle: nil)

    viewControllers = navigationControllers
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .primaryColor()
  }
}
