import UIKit

final class MovieDetailsViewController: UIViewController {

  // MARK: Inputs

  let movie: Movie
  let presenter: MovieDetailsPresenter
  let interactor: MovieDetailsRouteInteractor

  // MARK: Private properties

  private lazy var movieView: MovieDetailsView = {
    return MovieDetailsView(
      movie: self.movie,
      presenter: self.presenter,
      interactor: self.interactor
    )
  }()

  // MARK: Initialization

  init(movie: Movie, presenter: MovieDetailsPresenter, interactor: MovieDetailsRouteInteractor) {
    self.movie = movie
    self.presenter = presenter
    self.interactor = interactor
    super.init(nibName: nil, bundle: nil)

    title = movie.title
    navigationItem.titleView = ScrollingNavigationBarTitleView(title: movie.title)
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    automaticallyAdjustsScrollViewInsets = false
    hidesBottomBarWhenPushed = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .blackColor()
    view.addSubview(movieView)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.navigationBar.translucent = true
    navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    navigationController?.navigationBar.shadowImage = UIImage()

    if UIApplication.sharedApplication().statusBarOrientation == .LandscapeRight {
      UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }
  }
}

// MARK: - ZoomTransitionDelegate

extension MovieDetailsViewController: ZoomTransitionDelegate {
  var zoomTransitionView: UIView? { return movieView.infoView.posterImageView }
}

// MARK: - GateTransitionDelegate

extension MovieDetailsViewController: GateTransitionDelegate {
  var gateTransitionView: UIView? { return movieView.backdropImageView.imageViews.first }
}
