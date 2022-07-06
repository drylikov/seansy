import Compass
import Dip
import FontBlaster
import SteviaLayout
import Sugar
import UIKit
import XCGLogger

// MARK: Globals

let log = XCGLogger.defaultInstance()
let Cache = NSUserDefaults(suiteName: "group.kz.yenbekbay.Seansy-Dev")!

func navigate(urn: String) {
  let encodedUrn = urn.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
  guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
    url = NSURL(string: "\(Compass.scheme)\(encodedUrn)") else { return }

  appDelegate.openUrl(url)
}

// MARK: -

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

  // MARK: Private constants

  private let appScheme = "seansy"

  // MARK: Public properties

  var window: UIWindow?
  lazy var navigationController: UINavigationController = {
    return UINavigationController().then {
      $0.navigationBarHidden = true
      $0.interactivePopGestureRecognizer?.enabled = false
      $0.pushViewController(
        !Cache[.didRequestLocation] ? self.locationLocationVC : self.tabBarController,
        animated: false
      )
    }
  }()

  // MARK: Private properties

  private let dip = DependencyContainer() { dip in
    dip.register(.Singleton) {
      SeansyAPIProvider(payload: ["id": 2, "client": "ios"], secret: Secrets.seansyApiSecret)
    }
    dip.register(.Singleton) { DataManager(seansyApiProvider: try dip.resolve(), application: .sharedApplication()) }
  }
  private lazy var router: Router = {
    var router = Router()
    router.routes = [
      RoutePath.MovieList.rawValue: MovieListRoute(dataManager: try! self.dip.resolve()),
      RoutePath.MovieDetails.rawValue: MovieDetailsRoute(dataManager: try! self.dip.resolve())
    ]
    return router
  }()

  // View controllers
  private lazy var tabBarController: TabBarController = {
    return TabBarController(dataManager: try! self.dip.resolve())
  }()
  private lazy var locationLocationVC: LocationRequestViewController = {
    return LocationRequestViewController.new(try! self.dip.resolve()) { succeeded in
      Cache[.didRequestLocation] = true
      self.navigationController.pushViewController(self.tabBarController, animated: true)
    }
  }()

  // MARK: Public methods

  func openUrl(url: NSURL) -> Bool {
    if navigationController.visibleViewController != tabBarController { return false }

    return Compass.parse(url) { route, arguments in
      (self.tabBarController.selectedViewController as? UINavigationController)?.popToRootViewControllerAnimated(true)

      var navigationController: NavigationController
      switch RoutePath(rawValue: route)! {
      case .MovieList, .MovieDetails:
        navigationController = self.tabBarController.navigationControllers[0]
      }
      self.tabBarController.selectedViewController = navigationController
      self.router.navigate(route, arguments: arguments, navigationController: navigationController)
    }
  }

  // MARK: Private methods

  private func setAppearances() {
    UINavigationBar.appearance().style {
      $0.translucent = false
      $0.barStyle = .Black
      $0.barTintColor = .primaryColor()
      $0.tintColor = .whiteColor()
      $0.backIndicatorImage = UIImage(.BackIcon).icon
      $0.backIndicatorTransitionMaskImage = UINavigationBar.appearance().backIndicatorImage
      $0.titleTextAttributes = [ NSFontAttributeName: UIFont.regularFontOfSize(17) ]
    }
    UITabBar.appearance().style {
      $0.translucent = false
      $0.barStyle = .Black
      $0.barTintColor = .primaryColor()
      $0.tintColor = .accentColor()
    }

    UIBarButtonItem.appearance()
      .setTitleTextAttributes([ NSFontAttributeName: UIFont.regularFontOfSize(14) ], forState: .Normal)
    UITabBarItem.appearance()
      .setTitleTextAttributes([ NSFontAttributeName: UIFont.regularFontOfSize(11) ], forState: .Normal)

    UISwitch.appearance().tintColor = .accentColor()
    UISwitch.appearance().onTintColor = .accentColor()
    UISlider.appearance().tintColor = .accentColor()

    UITextField.appearance().keyboardAppearance = .Dark
  }
}

// MARK: - UIApplicationDelegate

extension AppDelegate {
  func application(application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
      log.setup(.Info,
        showThreadName: true,
        showLogLevel: true,
        showFileNames: false,
        showLineNumbers: false,
        showFunctionName: false
      )
      FontBlaster.blast()
      Compass.scheme = appScheme
      Compass.routes = [RoutePath.MovieDetails.rawValue]

      application.statusBarHidden = false
      setAppearances()

      let dataManager: DataManager = try! self.dip.resolve()
      dataManager.startLoading()

      window = UIWindow(frame: screenBounds)

      if let window = window {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
      }

      return true
  }

  func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    return openUrl(url)
  }
}
