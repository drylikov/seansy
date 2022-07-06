import NSObject_Rx
import Popover
import RxSwift
import RxCocoa
import Sugar
import Tactile
import UIKit

enum NavigationBarButtonItem {
  case Customize([PopoverMenuItem]), Date
}

final class SearchNavigationItemCoordinator: NSObject {

  // MARK: Inputs

  let navigationItem: UINavigationItem
  let navigationController: UINavigationController
  let interactor: SearchRouteInteractor

  // MARK: Public properties

  lazy var buttonItems: ControlProperty<[NavigationBarButtonItem]> = {
    let bindingObserver = UIBindingObserver(UIElement: self.navigationItem) {
      (navigationItem: UINavigationItem, buttonItems: [NavigationBarButtonItem]) in
      let barButtonItems: [UIBarButtonItem] = buttonItems
        .map {
          [
            self.barButtonItem($0),
            UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil).then { $0.width = 15 }
          ]
        }
        .flatten()
        .flatMap { $0 }
      if barButtonItems.count == 2 {
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = barButtonItems.first
      } else {
        navigationItem.rightBarButtonItems = barButtonItems
      }
    }

    return ControlProperty(values: Observable.just([]), valueSink: bindingObserver)
  }()

  let searchPlaceholder: Variable<String?> = Variable(nil)

  // MARK: Private properties

  private var dateMenu: DropdownMenu?
  private lazy var popover = Popover(options: [.Color(.accentColor()), .AnimationIn(0.2), .AnimationOut(0.4)])
  private lazy var searchTextField: SearchTextField = {
    return SearchTextField().then { $0.delegate = self }
  }()

  // MARK: Initialization

  init(navigationItem: UINavigationItem, navigationController: UINavigationController,
    interactor: SearchRouteInteractor) {
      self.navigationItem = navigationItem
      self.navigationController = navigationController
      self.interactor = interactor
      super.init()

      navigationItem.titleView = searchTextField
      searchPlaceholder.asObservable()
        .subscribeNext { self.searchTextField.placeholder = $0 }
        .addDisposableTo(rx_disposeBag)
  }

  // MARK: Private methods

  private func barButtonItem(buttonItem: NavigationBarButtonItem) -> UIBarButtonItem {
    let button = UIButton(frame: CGRect(width: 22, height: 22))
    switch buttonItem {
    case .Customize(let items):
      button.setImage(UIImage(.CustomizeIcon).icon, forState: .Normal)
      button.on(.TouchUpInside, { self.openCustomizeMenu($0, items: items) })
      if interactor.movieFilters == nil {
        button.enabled = false
        interactor.movieFiltersUpdates
          .subscribeNext { button.enabled = $0 }
          .addDisposableTo(rx_disposeBag)
      }
    case .Date:
      button.setImage(UIImage(.CalendarIcon).icon, forState: .Normal)
      button.on(.TouchUpInside, openDateMenu)
    }

    return UIBarButtonItem(customView: button)
  }

  private func openCustomizeMenu(button: UIButton, items: [PopoverMenuItem]) {
    let popoverMenu = PopoverMenu(
      frame: CGRect(size: CGSize(width: screenWidth, height: 0)),
      items: items,
      popover: popover
    )
    dismissDateMenu {
      self.popover.show(popoverMenu,
        point: CGPoint(x: button.frame.midX, y: self.navigationController.navigationBar.bottom))
    }
  }

  private func openDateMenu(button: UIButton) {
    if let dateMenu = dateMenu { return dateMenu.dismiss() }

    let items: [DropdownMenuItem] = interactor.dates.sort { $0 < $1 }.map { date in
      let item = DropdownMenuItem(title: date.longDateMenuString, handler: { _ in self.interactor.selectDate(date) })
      if interactor.selectedDate == date { item.selected = true }
      return item
    }
    dateMenu = DropdownMenu(navigationController: navigationController, items: items) { self.dateMenu = nil }
    navigationController.presentDropdownMenu(dateMenu!)
  }

  private func dismissDateMenu(completion: () -> Void) {
    if let dateMenu = dateMenu {
      dateMenu.dismiss(completion: completion)
    } else {
      completion()
    }
  }
}

// MARK: - UITextFieldDelegate

extension SearchNavigationItemCoordinator: UITextFieldDelegate {
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    dismissDateMenu {
      self.navigationController.pushSearch(self.searchPlaceholder.value, interactor: self.interactor, animated: false)
    }
    return false
  }
}
