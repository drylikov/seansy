import RxCocoa
import RxSwift
import UIKit

protocol ErrorableViewController {
  var view: UIView! { get }
  var errorMessageLabel: ErrorMessageLabel { get }
  func subscribeToReachableUpdates(updates: Driver<Bool>) -> Disposable
}

extension ErrorableViewController {
  func subscribeToReachableUpdates(updates: Driver<Bool>) -> Disposable {
    return updates
      .debounce(0.3)
      .driveNext { reachable in
        if !reachable {
          self.showErrorMessage("Нет подключения к интернету")
        } else {
          self.hideErrorMessage()
        }
    }
  }

  private func showErrorMessage(message: String) {
    errorMessageLabel.text = message
    errorMessageLabel.heightConstraint?.constant = 24
    UIView.animateWithDuration(0.3) { self.view.layoutIfNeeded() }
  }

  private func hideErrorMessage() {
    errorMessageLabel.heightConstraint?.constant = 0
    UIView.animateWithDuration(0.3,
      animations: { self.view.layoutIfNeeded() },
      completion: { _ in self.errorMessageLabel.text = nil })
  }
}
