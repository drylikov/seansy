import ObjectiveC
import UIKit

final class ScrollCoordinatorProxy: NSObject, UIScrollViewDelegate {

  // MARK: Inputs

  let scrollView: UIScrollView
  let coordinator: ScrollCoordinator
  let originalDelegate: UIScrollViewDelegate?

  // MARK: Private properties

  private var dragStartPosition = CGFloat(0)
  private var dragging = false

  // MARK: Initialization

  init(scrollView: UIScrollView, coordinator: ScrollCoordinator) {
    self.scrollView = scrollView
    self.coordinator = coordinator
    originalDelegate = scrollView.delegate
    super.init()

    scrollView.delegate = self
  }

  // MARK: NSObject

  override func respondsToSelector(aSelector: Selector) -> Bool {
    return shouldForwardSelector(aSelector)
      ? originalDelegate?.respondsToSelector(aSelector) ?? false
      : super.respondsToSelector(aSelector)
  }

  override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
    return shouldForwardSelector(aSelector) ? originalDelegate : nil
  }

  // MARK: Private methods

  func shouldForwardSelector(aSelector: Selector) -> Bool {
    return protocol_getMethodDescription(UIScrollViewDelegate.self, aSelector, false, true).types == nil &&
      protocol_getMethodDescription(UIScrollViewDelegate.self, aSelector, true, true).types == nil &&
      (protocol_getMethodDescription(UICollectionViewDelegate.self, aSelector, false, true).types != nil ||
        protocol_getMethodDescription(UICollectionViewDelegate.self, aSelector, true, true).types != nil ||
        protocol_getMethodDescription(UITableViewDelegate.self, aSelector, false, true).types != nil ||
        protocol_getMethodDescription(UITableViewDelegate.self, aSelector, true, true).types != nil)
  }

  // MARK: UIScrollViewDelegate

  func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    dragStartPosition = max(scrollView.contentOffset.y + scrollView.contentInset.top, 0)
    dragging = true
  }

  func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint,
    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
      if !dragging { return } else { dragging = false }

      let movement = targetContentOffset.memory.y + scrollView.contentInset.top - dragStartPosition
      if movement <= -coordinator.navigationBar.height / 2 {
        coordinator.setPercentHidden(0)
      } else if coordinator.percentHidden > 0 && coordinator.percentHidden < 1 && movement > 0 {
        coordinator.setPercentHidden(1)
      }
  }

  func scrollViewDidScroll(scrollView: UIScrollView) {
    let position = scrollView.contentOffset.y + scrollView.contentInset.top

    if position < 0 {
      coordinator.setPercentHidden(0)
    } else if dragging {
      let toBottom = scrollView.contentSize.height - scrollView.height - position
      let movement = position - dragStartPosition

      if toBottom <= 0 {
        coordinator.setPercentHidden(0)
      } else if coordinator.percentHidden < 1 && movement > 0 && !coordinator.animating {
        coordinator.setPercentHidden(movement / coordinator.navigationBar.height, interactive: true)
      }
    }
  }
}

// MARK: -

final class ScrollCoordinator {

  // MARK: Inputs

  let containerView: UIView
  let navigationBar: UINavigationBar

  // MARK: Private properties

  private var proxies: [ScrollCoordinatorProxy]!
  private var animating = false
  private var percentHidden = CGFloat(0) {
    didSet {
      proxies.map { $0.scrollView }.forEach {
        let toBottom = $0.contentSize.height - $0.height - $0.contentOffset.y - $0.contentInset.top
        if navigationBar.top < 0 && percentHidden == 0 && toBottom <= 0 {
          $0.contentOffset.y = $0.contentOffset.y + navigationBar.height
        }
      }

      navigationBar.top = -navigationBar.height * percentHidden + statusBarHeight * (1 - percentHidden)
      if percentHidden == 1.0 { navigationBar.top -= 1 }
      containerView.top = navigationBar.height * (1 - percentHidden) + statusBarHeight
      containerView.height = screenHeight - containerView.top - 44
    }
  }

  // MARK: Initialization

  init(scrollViews: [UIScrollView], containerView: UIView, navigationBar: UINavigationBar) {
    self.containerView = containerView
    self.navigationBar = navigationBar

    proxies = scrollViews.map { ScrollCoordinatorProxy(scrollView: $0, coordinator: self) }
  }

  // MARK: Public methods

  func restore() { percentHidden = 0 }

  // MARK: Private methods

  private func setPercentHidden(percentHidden: CGFloat, interactive: Bool = false) {
    let newPercentHidden = max(0.0, min(1.0, percentHidden))
    if newPercentHidden == self.percentHidden { return }

    if !interactive {
      animating = true
      UIView.animateWithDuration(Double(UINavigationControllerHideShowBarDuration), delay: 0,
        usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [],
        animations: { self.percentHidden = newPercentHidden },
        completion: { _ in self.animating = false })
    } else {
      self.percentHidden = newPercentHidden
    }
  }
}
