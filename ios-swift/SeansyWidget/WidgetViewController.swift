import Dip
import NotificationCenter
import RxSwift
import UIKit
import XCGLogger

let log = XCGLogger.defaultInstance()
let Cache = NSUserDefaults(suiteName: "group.kz.yenbekbay.Seansy-Dev")!

final class TodayViewController: UIViewController, NCWidgetProviding {
  private let dip = DependencyContainer() { dip in
    dip.register(.Singleton) {
      SeansyAPIProvider(payload: ["id": 2, "client": "ios"], secret: Secrets.seansyApiSecret)
    }
    dip.register(.Singleton) { DataManager(seansyApiProvider: try dip.resolve()) }
  }

  private lazy var disposeBag = DisposeBag()

  // MARK: View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    let dataManager: DataManager = try! dip.resolve()
    dataManager.dataUpdates.subscribeNext { movies, cinemas, showtimes, change in
      log.info("Success")
    }.addDisposableTo(disposeBag)
  }

  func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
    // Perform any setup necessary in order to update the view.

    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData

    completionHandler(NCUpdateResult.NewData)
  }
}
