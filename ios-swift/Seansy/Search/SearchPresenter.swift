import NSObject_Rx
import Reusable
import RxDataSources
import RxSwift
import Sugar
import UIKit

final class SearchPresenter: NSObject, Presenter {

  // MARK: Inputs

  let viewController: SearchViewController
  let interactor: SearchInteractor

  // MARK: Public properties

  private(set) weak var transitionView: UIView?

  // MARK: Private properties

  private var searchTextField: SearchTextField { return viewController.searchTextField }
  private var onboardingView: UIScrollView { return viewController.onboardingView }
  private var resultsView: UIScrollView { return viewController.resultsView }
  private var recentSearchesView: RecentSearchesView { return viewController.recentSearchesView }
  private var recentSearchesWrapperView: CustomViewWrapperTableView { return viewController.recentSearchesWrapperView }
  private var queryExamplesView: SearchItemsView { return viewController.queryExamplesView }
  private var suggestionsView: SearchItemsView { return viewController.suggestionsView }
  private var movieResultsView: MovieSummaryListView { return viewController.movieResultsView }
  private var cinemaResultsView: CinemaSummaryListView { return viewController.cinemaResultsView }
  private let movieResultsDataSource = RxTableViewSectionedReloadDataSource<MovieSummaryListSection>()
  private let cinemaResultsDataSource = RxTableViewSectionedReloadDataSource<CinemaSummaryListSection>()
  private var searching = Variable(false)

  // MARK: Initialization

  init(viewController: SearchViewController, interactor: SearchInteractor) {
    self.viewController = viewController
    self.interactor = interactor
    super.init()

    searching.asObservable().bindTo(onboardingView.rx_hidden).addDisposableTo(rx_disposeBag)
    searching.asObservable().map { !$0 }.bindTo(resultsView.rx_hidden).addDisposableTo(rx_disposeBag)
    searchTextField.textObservable.map { !$0.isEmpty }.bindTo(searching).addDisposableTo(rx_disposeBag)

    [recentSearchesWrapperView, queryExamplesView, movieResultsView, cinemaResultsView].forEach {
      $0.sectionHeaderHeight = ListSectionHeaderView.height
      $0.registerReusableHeaderFooterView(ListSectionHeaderView)
    }
    recentSearchesWrapperView.rowHeight = recentSearchesView.height
    [recentSearchesWrapperView, queryExamplesView, suggestionsView, movieResultsView, cinemaResultsView]
      .forEach { $0.delegate = self }
    recentSearchesView.delegate = self

    setUpDataSources()
  }

  // MARK: Public methods

  func startLoading() {
    recentSearchesView.sectionedDataSource.setSections([SearchItemsSection(items: interactor.recentSearches)])
    recentSearchesWrapperView.sectionedDataSource.setSections([CustomViewWrapperSection(items: [recentSearchesView])])

    queryExamplesView.sectionedDataSource.setSections([SearchItemsSection(items: interactor.queryExamples)])
    queryExamplesView.dataSource = queryExamplesView.sectionedDataSource

    let suggestions = searchTextField.textObservable
      .map(interactor.suggestionsForQuery)
      .shareReplay(1)
    let results = suggestions
      .map { $0.map { self.interactor.resultsFromSuggestion($0) }.flatMap { $0 } }
      .shareReplay(1)

    suggestions
      .map { [SearchItemsSection(items: $0)] }
      .bindTo(suggestionsView.rx_itemsWithDataSource(suggestionsView.sectionedDataSource))
      .addDisposableTo(rx_disposeBag)
    results
      .map { results in
        let movies = results.map { $0.movies }.flatten().flatMap { $0 }.unique.limit(3)
        return movies.isEmpty ? [] : [MovieSummaryListSection(movies: movies, title: "Фильмы")]
      }
      .bindTo(movieResultsView.rx_itemsWithDataSource(movieResultsDataSource))
      .addDisposableTo(rx_disposeBag)
    results
      .map { results in
        let cinemas = results.map { $0.cinemas }.flatten().flatMap { $0 }.unique.limit(3)
        return cinemas.isEmpty ? [] : [CinemaSummaryListSection(cinemas: cinemas, title: "Кинотеатры")]
      }
      .bindTo(cinemaResultsView.rx_itemsWithDataSource(cinemaResultsDataSource))
      .addDisposableTo(rx_disposeBag)
  }

  // MARK: Private methods

  func setUpDataSources() {
    movieResultsDataSource.configureCell = { _, tableView, indexPath, movie in
      return tableView
        .dequeueReusableCell(indexPath: indexPath, cellType: MovieSummaryListCell.self)
        .then { $0.configure(movie, interactor: self.interactor) }
    }
    cinemaResultsDataSource.configureCell = { _, tableView, indexPath, cinema in
      return tableView
        .dequeueReusableCell(indexPath: indexPath, cellType: CinemaSummaryListCell.self)
        .then { $0.configure(cinema) }
    }
  }
}

// MARK: - UITableViewDelegate

extension SearchPresenter: UITableViewDelegate {
  func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if tableView == suggestionsView { return nil }

    return tableView.dequeueReusableHeaderFooterView(ListSectionHeaderView)?.then {
      switch tableView {
      case recentSearchesWrapperView:
        $0.configure("Недавние поиски")
      case queryExamplesView:
        $0.configure("Примеры запросов")
      case movieResultsView:
        $0.configure(movieResultsDataSource.sectionAtIndex(section).title)
      case cinemaResultsView:
        $0.configure(cinemaResultsDataSource.sectionAtIndex(section).title)
      default: break
      }
    }
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch tableView {
    case queryExamplesView:
      searchTextField.text = queryExamplesView.sectionedDataSource.itemAtIndexPath(indexPath).query + " "
      searchTextField.becomeFirstResponder()
    case suggestionsView:
      searchTextField.text = suggestionsView.sectionedDataSource.itemAtIndexPath(indexPath).query + " "
      searchTextField.becomeFirstResponder()
    case movieResultsView:
      transitionView = movieResultsView.cellForRowAtIndexPath(indexPath)
      let movie = movieResultsDataSource.itemAtIndexPath(indexPath)
      viewController.pushMovieDetails(movie, interactor: interactor, animated: true)
    default: break
    }

    tableView.deselectRowAtIndexPath(indexPath, animated: false)
  }
}

// MARK: - UICollectionViewDelegate

extension SearchPresenter: UICollectionViewDelegate {
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    if collectionView == recentSearchesView {
      searchTextField.text = recentSearchesView.sectionedDataSource.itemAtIndexPath(indexPath).query + " "
      searchTextField.becomeFirstResponder()
    }
  }
}
