import NSObject_Rx
import Reusable
import RxCocoa
import RxSwift
import SteviaLayout
import Sugar
import UIKit

final class SearchViewController: UIViewController {

  // MARK: Inputs

  var presenter: SearchPresenter!

  // MARK: Public properties

  private(set) lazy var searchTextField = SearchTextField()
  private(set) lazy var onboardingView = UIScrollView().then { $0.indicatorStyle = .White }
  private(set) lazy var resultsView = UIScrollView().then {
    $0.indicatorStyle = .White
    $0.hidden = true
  }
  private(set) lazy var recentSearchesView = RecentSearchesView(frame: CGRect(width: screenWidth, height: 140))
  private(set) lazy var recentSearchesWrapperView = CustomViewWrapperTableView().then { $0.bounces = false }
  private(set) lazy var queryExamplesView = SearchItemsView().then { $0.bounces = false }
  private(set) lazy var suggestionsView = SearchItemsView().then { $0.bounces = false }
  private(set) lazy var movieResultsView = MovieSummaryListView().then { $0.bounces = false }
  private(set) lazy var cinemaResultsView = CinemaSummaryListView().then { $0.bounces = false }

  // MARK: Initialization

  init(placeholder: String?) {
    super.init(nibName: nil, bundle: nil)

    searchTextField.placeholder = placeholder
    navigationItem.titleView = searchTextField
    navigationItem.hidesBackButton = true
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
      target: self, action: #selector(SearchViewController.dismiss))
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor()
    view.sv(
      onboardingView.sv(
        recentSearchesWrapperView,
        queryExamplesView
      ),
      resultsView.sv(
        suggestionsView,
        movieResultsView,
        cinemaResultsView
      )
    )
    [onboardingView, resultsView].forEach {
      $0.fillContainer()
      $0.on(UITapGestureRecognizer().then { $0.delegate = self }) { _ in self.searchTextField.resignFirstResponder() }
      $0.keyboardDismissMode = .OnDrag
    }
    observeBottom(recentSearchesWrapperView) { self.queryExamplesView.top = $0 }
    observeBottom(queryExamplesView) { self.onboardingView.contentSize.height = $0 }
    observeBottom(suggestionsView) { self.movieResultsView.top = $0 }
    observeBottom(movieResultsView) { self.cinemaResultsView.top = $0 }
    observeBottom(cinemaResultsView) { self.resultsView.contentSize.height = $0 }
    [recentSearchesWrapperView, queryExamplesView, suggestionsView, movieResultsView, cinemaResultsView].forEach {
      $0.width = screenWidth
      syncHeightWithContentSize($0)
    }

    searchTextField.becomeFirstResponder()
    presenter.startLoading()
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.interactivePopGestureRecognizer?.enabled = false
    navigationController?.navigationBar.translucent = false
    navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
    navigationController?.navigationBar.shadowImage = nil
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.interactivePopGestureRecognizer?.enabled = true
  }

  // MARK: Public methods

  func dismiss() { navigationController?.popViewControllerAnimated(false) }

  // MARK: Private methods

  private func observeBottom(view: UIView, onNext: CGFloat -> Void) {
    view.rx_observe(CGRect.self, "frame")
      .map { $0.flatMap { $0.origin.y + $0.height } ?? 0 }
      .subscribeNext(onNext)
      .addDisposableTo(rx_disposeBag)
  }

  private func syncHeightWithContentSize(scrollView: UIScrollView) {
    scrollView.rx_observe(CGSize.self, "contentSize")
      .map { $0?.height ?? 0 }
      .subscribeNext { scrollView.height = $0 }
      .addDisposableTo(rx_disposeBag)
  }
}

// MARK: - UIGestureRecognizerDelegate

extension SearchViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    if !onboardingView.hidden {
      if recentSearchesView.indexPathForItemAtPoint(touch.locationInView(recentSearchesView)) != nil { return false }
      if queryExamplesView.indexPathForRowAtPoint(touch.locationInView(queryExamplesView)) != nil { return false }
    } else {
      for tableView in [suggestionsView, movieResultsView] {
        if tableView.indexPathForRowAtPoint(touch.locationInView(tableView)) != nil { return false }
      }
    }

    return true
  }
}

// MARK: - GateTransitionDelegate

extension SearchViewController: GateTransitionDelegate {
  var gateTransitionView: UIView? { return presenter.transitionView }
}
