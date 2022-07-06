import UIKit

// MARK: Protocol Definitions

protocol Transitionable {
  func setInfoAlpha(alpha: CGFloat)
}

protocol GateTransitionDelegate {
  var gateTransitionView: UIView? { get }
}

protocol ZoomTransitionDelegate {
  var zoomTransitionView: UIView? { get }
}

// MARK: -

class TransitionManager: NSObject {

  // MARK: Inputs

  let dismissing: Bool
  let navigationController: NavigationController

  // MARK: Private constants

  private let duration: NSTimeInterval = 0.3

  // MARK: Initialization

  init(navigationController: NavigationController, dismissing: Bool) {
    self.navigationController = navigationController
    self.dismissing = dismissing
    super.init()
  }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension TransitionManager: UIViewControllerAnimatedTransitioning {
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {}
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return duration
  }
}

// MARK: -

final class ZoomTransitionManager: TransitionManager {

  // MARK: Inputs

  let sourceDelegate: ZoomTransitionDelegate
  let destinationDelegate: ZoomTransitionDelegate

  // MARK: Initialization

  init(sourceDelegate: ZoomTransitionDelegate, destinationDelegate: ZoomTransitionDelegate,
    navigationController: NavigationController, dismissing: Bool) {
      self.sourceDelegate = sourceDelegate
      self.destinationDelegate = destinationDelegate
      super.init(navigationController: navigationController, dismissing: dismissing)
  }

  // MARK: UIViewControllerAnimatedTransitioning

  override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    var fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
    var toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
    let containerView = transitionContext.containerView()!
    var sourceView = sourceDelegate.zoomTransitionView!
    var destinationView = destinationDelegate.zoomTransitionView!
    let startFrame = sourceView.superview!.convertRect(sourceView.frame, toView: navigationController.view)
    let endFrame = destinationView.superview!.convertRect(destinationView.frame, toView: navigationController.view)
    let distance = distanceFromPoint(startFrame.center, size: toVC.view.size)

    if dismissing {
      swap(&fromVC, &toVC)
      swap(&sourceView, &destinationView)
    }

    containerView.addSubview(fromVC.view)
    containerView.addSubview(toVC.view)

    let maskView = UIView(frame: dismissing ? toVC.view.frame : startFrame).then { $0.backgroundColor = .blackColor() }
    toVC.view.maskView = maskView

    let oldSourceViewSuperview = sourceView.superview!
    sourceView.removeFromSuperview()
    containerView.addSubview(sourceView)
    sourceView.frame = startFrame
    (sourceView as? Transitionable)?.setInfoAlpha(dismissing ? 0 : 1)
    destinationView.hidden = true

    UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: transitionContext.isInteractive() ? 1 : 0.75,
      initialSpringVelocity: 0, options: .CurveEaseInOut,
      animations: {
        sourceView.frame = endFrame
        (sourceView as? Transitionable)?.setInfoAlpha(self.dismissing ? 1 : 0)
        maskView.frame = self.dismissing ? endFrame : startFrame.insetBy(dx: -distance, dy: -distance)
      },
      completion: { _ in
        toVC.view.maskView = nil
        sourceView.removeFromSuperview()
        oldSourceViewSuperview.addSubview(sourceView)
        sourceView.frame = oldSourceViewSuperview
          .convertRect(self.dismissing ? endFrame : startFrame, fromView: containerView)
        (sourceView as? Transitionable)?.setInfoAlpha(1)
        destinationView.hidden = false
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
    })
  }

  // MARK: Private methods

  private func distanceFromPoint(point: CGPoint, size: CGSize) -> CGFloat {
    switch (point.x < size.width / 2, point.y < size.height / 2) {
    case (true, true):
      return sqrt((point.x - size.width) * (point.x - size.width) + (point.y - size.height) * (point.y - size.height))
    case (true, false):
      return sqrt((point.x - size.width) * (point.x - size.width) + point.y * point.y)
    case (false, true):
      return sqrt(point.x * point.x + (point.y - size.height) * (point.y - size.height))
    case (false, false):
      return sqrt(point.x * point.x + point.y * point.y)
    }
  }
}

// MARK: -

final class GateTransitionManager: TransitionManager {

  // MARK: Inputs

  let sourceDelegate: GateTransitionDelegate
  let destinationDelegate: GateTransitionDelegate

  // MARK: Initialization

  init(sourceDelegate: GateTransitionDelegate, destinationDelegate: GateTransitionDelegate,
    navigationController: NavigationController, dismissing: Bool) {
      self.sourceDelegate = sourceDelegate
      self.destinationDelegate = destinationDelegate
      super.init(navigationController: navigationController, dismissing: dismissing)
  }

  // MARK: UIViewControllerAnimatedTransitioning

  override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    var fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
    var toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
    let containerView = transitionContext.containerView()!
    var sourceView = sourceDelegate.gateTransitionView!
    var destinationView = destinationDelegate.gateTransitionView!
    let startFrame = sourceView.superview!.convertRect(sourceView.frame, toView: navigationController.view)
    let endFrame = destinationView.superview!.convertRect(destinationView.frame, toView: navigationController.view)

    if dismissing {
      swap(&fromVC, &toVC)
      swap(&sourceView, &destinationView)
    }

    let (topPosition, topView, bottomView) = splitView(fromVC.view, atView: sourceView)
    let gateView = UIView(frame: fromVC.view.frame).then {
      $0.clipsToBounds = true
      $0.addSubview(topView)
      $0.addSubview(bottomView)
    }

    containerView.addSubview(toVC.view)
    containerView.addSubview(gateView)

    let oldSourceViewSuperview = sourceView.superview!
    sourceView.removeFromSuperview()
    containerView.addSubview(sourceView)
    sourceView.frame = startFrame
    (sourceView as? Transitionable)?.setInfoAlpha(dismissing ? 0 : 1)
    destinationView.hidden = true

    UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: transitionContext.isInteractive() ? 1 : 0.9,
      initialSpringVelocity: 0, options: .CurveEaseInOut,
      animations: {
        sourceView.frame = endFrame
        (sourceView as? Transitionable)?.setInfoAlpha(self.dismissing ? 1 : 0)
        topView.top = self.dismissing ? 0 : -topPosition
        bottomView.top = self.dismissing ? 0 : bottomView.height - topPosition
      },
      completion: { _ in
        if self.dismissing { containerView.addSubview(fromVC.view) }
        gateView.removeFromSuperview()
        sourceView.removeFromSuperview()
        oldSourceViewSuperview.addSubview(sourceView)
        sourceView.frame = oldSourceViewSuperview
          .convertRect(self.dismissing ? endFrame : startFrame, fromView: containerView)
        (sourceView as? Transitionable)?.setInfoAlpha(1)
        destinationView.hidden = false
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
    })
  }

  // MARK: Private methods

  private func splitView(view: UIView, atView: UIView) -> (CGFloat, UIView, UIView) {
    let snapshot = UIImage(view: view)
    let topPosition = atView.superview!.convertRect(atView.frame, toView: view).origin.y
    let topView = UIImageView(frame: view.bounds).then {
      $0.image = snapshot
      $0.maskView = UIView(frame: heightLens.to(topPosition, $0.bounds)).then { $0.backgroundColor = .blackColor() }
      $0.top = dismissing ? -topPosition : 0
    }
    let bottomView = UIImageView(frame: view.bounds).then {
      $0.image = snapshot
      $0.maskView = UIView(frame: CGRect(x: 0, y: topPosition + atView.height,
        width: $0.width, height: $0.height - topPosition - atView.height)).then { $0.backgroundColor = .blackColor() }
      $0.top = dismissing ? $0.height - topPosition : 0
    }

    return (topPosition, topView, bottomView)
  }
}
