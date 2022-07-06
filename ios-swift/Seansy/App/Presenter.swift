import Foundation

protocol Presenter {
  var zoomTransitionView: UIView? { get }
  var gateTransitionView: UIView? { get }
  var hasContent: Bool { get }
  func startLoading()
  func retryLoading()
}

extension Presenter {
  var zoomTransitionView: UIView? { return nil }
  var gateTransitionView: UIView? { return nil }
  var hasContent: Bool { return false }
  func retryLoading() {}
}
