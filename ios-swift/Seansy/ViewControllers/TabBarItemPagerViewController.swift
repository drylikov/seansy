import NSObject_Rx
import RxCocoa
import RxSwift
import SteviaLayout
import UIKit
import Whisper
import XLPagerTabStrip

// MARK: -

typealias Child = TabBarItemPagerChildViewController

class TabBarItemPagerViewController<T: Child>: ButtonBarPagerTabStripViewController, ErrorableViewController {

  // MARK: Inputs

  let childVCs: [T]
  let interactor: SearchRouteInteractor

  // MARK: Public properties

  let errorMessageLabel = ErrorMessageLabel()
  var navigationItemCoordinator: SearchNavigationItemCoordinator!

  // MARK: Private properties

  private var scrollCoordinator: ScrollCoordinator!

  // MARK: Initialization

  required init(childVCs: [T], interactor: SearchRouteInteractor) {
    self.childVCs = childVCs
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
    changeCurrentIndexProgressive = { oldCell, newCell, _, changeCurrentIndex, _ in
      if !changeCurrentIndex { return }

      oldCell?.label.textColor = UIColor.whiteColor().alpha(0.5)
      newCell?.label.textColor = .whiteColor()
    }

    setUpButtonBarView()
    view.sv(buttonBarView, errorMessageLabel, containerView)

    super.viewDidLoad()

    let hairlineHeight = 1 / UIScreen.mainScreen().scale
    view.layout(
      0,
      |buttonBarView| ~ 44,
      hairlineHeight,
      |errorMessageLabel| ~ 0,
      hairlineHeight,
      |containerView|,
      0
    )

//    scrollCoordinator = ScrollCoordinator(
//      scrollViews: childVCs.map { $0.scrollView },
//      containerView: view,
//      navigationBar: navigationController!.navigationBar
//    )
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
//    scrollCoordinator.restore()
  }

  // MARK: Private methods

  private func setUpButtonBarView() {
    buttonBarView.optimize()
    settings.style.buttonBarBackgroundColor = .primaryColor()
    settings.style.buttonBarItemBackgroundColor = .clearColor()
    settings.style.buttonBarItemFont = .regularFontOfSize(14)
    settings.style.buttonBarItemsShouldFillAvailiableWidth = true
    settings.style.buttonBarLeftContentInset = 0
    settings.style.buttonBarMinimumLineSpacing = 0
    settings.style.buttonBarRightContentInset = 0
    settings.style.selectedBarBackgroundColor = .accentColor()
    settings.style.selectedBarHeight = 2.0
  }

  // MARK: PagerTabStripDataSource

  override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController)
    -> [UIViewController] { return childVCs }
}

// MARK: - ZoomTransitionDelegate

extension TabBarItemPagerViewController: ZoomTransitionDelegate {
  var zoomTransitionView: UIView? { return childVCs[currentIndex].zoomTransitionView }
}

// MARK: - GateTransitionDelegate

extension TabBarItemPagerViewController: GateTransitionDelegate {
  var gateTransitionView: UIView? { return childVCs[currentIndex].gateTransitionView }
}
