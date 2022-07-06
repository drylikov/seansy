import Compass
import UIKit

enum RoutePath: String {
  case MovieList = "movies:{type}"
  case MovieDetails = "movie:{id}"
}

// MARK: -

class Route: NSObject, Routable {

  // MARK: Inputs

  let dataManager: DataManager

  // MARK: Initialization

  init(dataManager: DataManager) {
    self.dataManager = dataManager
    super.init()
  }

  // MARK: Routable

  func resolve(arguments: [String: String], navigationController: UINavigationController?) {
    navigationController?.presentError(title: "Ошибка", subtitle: "Что-то пошло не так.")
  }
}
