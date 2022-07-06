import UIKit

final class NavigationController: UINavigationController {

  // MARK: Private properties

  private lazy var panGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
    return UIScreenEdgePanGestureRecognizer(target: self, action: #selector(NavigationController.handlePan(_:))).then {
      $0.edges = .Left
      $0.delegate = self
    }
  }()
  private var disabledGestureRecognizers = [UIGestureRecognizer]()
  private var interactionTransitionController: UIPercentDrivenInteractiveTransition?

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    interactivePopGestureRecognizer?.delegate = self
    view.addGestureRecognizer(panGestureRecognizer)
  }

  // MARK: Gesture recognizer

  func handlePan(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
    let velocity = gestureRecognizer.velocityInView(view)
    let progress = min(1, max(0, gestureRecognizer.translationInView(view).x / view.width))

    switch gestureRecognizer.state {
    case .Began:
      interactionTransitionController = UIPercentDrivenInteractiveTransition()
      popViewControllerAnimated(true)
    case .Changed:
      interactionTransitionController?.updateInteractiveTransition(progress)
    case .Ended:
      if progress > 0.5 || velocity.x > 0 {
        interactionTransitionController?.finishInteractiveTransition()
      } else {
        interactionTransitionController?.cancelInteractiveTransition()
      }
      interactionTransitionController = nil
    default: return
    }
  }
}

// MARK: - UINavigationControllerDelegate

extension NavigationController: UINavigationControllerDelegate {
  func navigationController(navigationController: UINavigationController,
    willShowViewController viewController: UIViewController, animated: Bool) {
      disabledGestureRecognizers.forEach { $0.enabled = true }
      disabledGestureRecognizers.removeAll()
  }

  func navigationController(navigationController: UINavigationController,
    animationControllerForOperation operation: UINavigationControllerOperation,
    fromViewController fromVC: UIViewController,
    toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
      if let sourceDelegate = fromVC as? ZoomTransitionDelegate,
        destinationDelegate = toVC as? ZoomTransitionDelegate {
          if sourceDelegate.zoomTransitionView != nil && destinationDelegate.zoomTransitionView != nil {
            return ZoomTransitionManager(
              sourceDelegate: sourceDelegate,
              destinationDelegate: destinationDelegate,
              navigationController: self,
              dismissing: operation != .Push
            )
          }
      }
      if let sourceDelegate = fromVC as? GateTransitionDelegate,
        destinationDelegate = toVC as? GateTransitionDelegate {
          if sourceDelegate.gateTransitionView != nil && destinationDelegate.gateTransitionView != nil {
            return GateTransitionManager(
              sourceDelegate: sourceDelegate,
              destinationDelegate: destinationDelegate,
              navigationController: self,
              dismissing: operation != .Push
            )
          }
      }

      return nil
  }

  func navigationController(navigationController: UINavigationController,
    interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
      return interactionTransitionController
  }
}

// MARK: - UIGestureRecognizerDelegate

extension NavigationController: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      if (gestureRecognizer == panGestureRecognizer || gestureRecognizer == interactivePopGestureRecognizer) &&
        gestureRecognizer.state != .Failed {
          otherGestureRecognizer.enabled = false
          disabledGestureRecognizers.append(otherGestureRecognizer)
      }

      return true
  }

  func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let transitionCoordinator = transitionCoordinator() {
      if transitionCoordinator.isAnimated() { return false }
    }

    if viewControllers.count < 2 { return false }

    var useCustomGestureRecognizer = false
    if let sourceDelegate = viewControllers[viewControllers.count - 1] as? ZoomTransitionDelegate,
      destinationDelegate = viewControllers[viewControllers.count - 2] as? ZoomTransitionDelegate {
        useCustomGestureRecognizer = sourceDelegate.zoomTransitionView != nil &&
          destinationDelegate.zoomTransitionView != nil
    }
    if !useCustomGestureRecognizer {
      if let sourceDelegate = viewControllers[viewControllers.count - 1] as? GateTransitionDelegate,
        destinationDelegate = viewControllers[viewControllers.count - 2] as? GateTransitionDelegate {
          useCustomGestureRecognizer = sourceDelegate.gateTransitionView != nil &&
            destinationDelegate.gateTransitionView != nil
      }
    }

    if useCustomGestureRecognizer {
      return gestureRecognizer == panGestureRecognizer
    } else {
      return gestureRecognizer == interactivePopGestureRecognizer
    }
  }
}
