import Foundation
import StatefulViewController
import SteviaLayout

class TabBarItemPagerChildViewController: UIViewController, StatefulViewController {

  // MARK: Inputs

  var presenter: Presenter!

  // MARK: Public properties

  var scrollView: UIScrollView { fatalError("Must override") }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.sv(scrollView)
    scrollView.fillContainer()

    loadingView = LoadingView(frame: view.frame)
    emptyView = EmptyView(frame: view.frame)
    errorView = ErrorView(frame: view.frame, reloadHandler: presenter.retryLoading)

    presenter.startLoading()
  }

  // MARK: StatefulViewController

  func hasContent() -> Bool { return presenter.hasContent }
}

// MARK: - ZoomTransitionDelegate

extension TabBarItemPagerChildViewController: ZoomTransitionDelegate {
  var zoomTransitionView: UIView? { return presenter.zoomTransitionView }
}

// MARK: - GateTransitionDelegate

extension TabBarItemPagerChildViewController: GateTransitionDelegate {
  var gateTransitionView: UIView? { return presenter.gateTransitionView }
}
