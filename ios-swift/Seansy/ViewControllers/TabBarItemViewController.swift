import NSObject_Rx
import RxCocoa
import RxSwift
import StatefulViewController
import SteviaLayout
import UIKit

class TabBarItemViewController: UIViewController, StatefulViewController, ErrorableViewController {

  // MARK: Inputs

  let interactor: SearchRouteInteractor
  var presenter: Presenter!

  // MARK: Public properties

  var scrollView: UIScrollView { fatalError("Must override") }
  let errorMessageLabel = ErrorMessageLabel()
  var navigationItemCoordinator: SearchNavigationItemCoordinator!

  // MARK: Private properties

  private var scrollCoordinator: ScrollCoordinator!

  // MARK: Initialization

  required init(interactor: SearchRouteInteractor) {
    self.interactor = interactor
    super.init(nibName: nil, bundle: nil)

    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    automaticallyAdjustsScrollViewInsets = false
    edgesForExtendedLayout = .None
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.sv(scrollView, errorMessageLabel)
    view.layout(
      0,
      |errorMessageLabel| ~ 0,
      1 / UIScreen.mainScreen().scale,
      |scrollView|,
      0
    )

    loadingView = LoadingView(frame: view.frame)
    emptyView = EmptyView(frame: view.frame)
    errorView = ErrorView(frame: view.frame, reloadHandler: presenter.retryLoading)

    scrollCoordinator = ScrollCoordinator(
      scrollViews: [scrollView],
      containerView: view,
      navigationBar: navigationController!.navigationBar
    )
    navigationItemCoordinator = SearchNavigationItemCoordinator(
      navigationItem: navigationItem,
      navigationController: navigationController!,
      interactor: interactor
    )

    subscribeToReachableUpdates(interactor.reachableUpdates).addDisposableTo(rx_disposeBag)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.navigationBar.translucent = false
    navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
    navigationController?.navigationBar.shadowImage = nil
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    scrollCoordinator.restore()
  }

  // MARK: StatefulViewController

  func hasContent() -> Bool { return presenter.hasContent }
}

// MARK: - ZoomTransitionDelegate

extension TabBarItemViewController: ZoomTransitionDelegate {
  var zoomTransitionView: UIView? { return presenter.zoomTransitionView }
}

// MARK: - GateTransitionDelegate

extension TabBarItemViewController: GateTransitionDelegate {
  var gateTransitionView: UIView? { return presenter.gateTransitionView }
}
