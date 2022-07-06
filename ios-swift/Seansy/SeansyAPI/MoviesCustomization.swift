import UIKit

final class MoviesCustomization {

  // MARK: Inputs

  let navigationController: UINavigationController
  let interactor: MoviesCustomizationInteractor

  // MARK: Public properties

  lazy var barButtonItem: NavigationBarButtonItem = {
    return .Customize([
      PopoverMenuItem(title: "Сортировать", image: UIImage(.SortIcon), handler: self.openSortView),
      PopoverMenuItem(title: "Фильтровать", image: UIImage(.FilterIcon), handler: self.openFilterView)])
  }()

  // MARK: Initialization

  init(navigationController: UINavigationController, interactor: MoviesCustomizationInteractor) {
    self.navigationController = navigationController
    self.interactor = interactor
  }

  // MARK: Private methods

  private func openSortView() {
    let items: [ActionSheetItem] = ([.Title, .Popularity, .Rating, .ShowtimesCount] as [MoviesSortBy]).map { sortBy in
      let item = ActionSheetItem(title: sortBy.title, image: UIImage(sortBy.asset), handler: {
        self.interactor.resortMovies(sortBy)
      })
      if self.interactor.moviesSortBy == sortBy { item.selected = true }
      return item
    }
    navigationController.presentActionSheet(ActionSheet(title: "Сортировать фильмы", items: items))
  }

  private func openFilterView() {
    let factory = MovieFiltersViewFactory(filters: interactor.movieFilters!)
    let items = [factory.ratingSlider, factory.runtimeSlider, factory.childrenSwitch, factory.genresSelector]
      .map { ActionSheetItem(view: $0) }
    navigationController.presentActionSheet(
      ActionSheet(title: "Фильтровать фильмы", cancelTitle: "Готово", items: items) {
        self.interactor.refilterMovies()
      })
  }
}
