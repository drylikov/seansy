import Hue
import InfiniteCollectionView
import Kingfisher
import NSObject_Rx
import Reusable
import RxSwift
import Sugar
import UIKit

struct MovieListCarouselHeaderViewItem {

  // MARK: Inputs

  let movie: Movie?
  let imageUrl: NSURL?
  let handler: UIView? -> Void

  // MARK; Initialization

  init(movie: Movie, handler: UIView? -> Void) {
    self.movie = movie
    self.handler = handler
    imageUrl = nil
  }

  init(imageUrl: NSURL, handler: UIView? -> Void) {
    self.imageUrl = imageUrl
    self.handler = handler
    movie = nil
  }
}

// MARK: -

final class MovieListCarouselHeaderViewCell: MovieSummaryCollectionViewCell {

  // MARK: MovieSummaryCollectionViewCell

  override func factoryForBounds(bounds: CGRect) -> MovieSummaryViewFactory {
    return MovieBackdropSummaryViewFactory(bounds: bounds)
  }

  // MARK: Public methods

  func configure(item: MovieListCarouselHeaderViewItem, interactor: BackdropColorsInteractor?) {
    guard let factory = factory as? MovieBackdropSummaryViewFactory else { return }

    if let movie = item.movie {
      factory.configure(movie: movie, interactor: interactor)
    } else if let imageUrl = item.imageUrl {
      factory.configure(imageUrl: imageUrl)
    }
  }
}

// MARK: -

final class MovieListCarouselHeaderView: UICollectionReusableView, Reusable {

  // MARK: Inputs

  var interactor: MovieListInteractor?

  // MARK: Public properties

  var items = [MovieListCarouselHeaderViewItem]() {
    didSet {
      collectionView.reloadData()
      if activityIndicatorView.isAnimating() && !items.isEmpty {
        prefetchImages()
          .subscribeCompleted {
            self.activityIndicatorView.stopAnimating()
            UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0,
              options: [], animations: { self.collectionView.layer.transform = CATransform3DIdentity }, completion: nil)
          }
          .addDisposableTo(rx_disposeBag)
      }
    }
  }

  // MARK: Private properties

  private var cells = [NSIndexPath: MovieListCarouselHeaderViewCell]()

  // Views
  private lazy var activityIndicatorView: UIActivityIndicatorView = {
    return UIActivityIndicatorView(activityIndicatorStyle: .White).then {
      $0.frame = self.bounds
      $0.startAnimating()
    }
  }()
  private lazy var collectionView: InfiniteCollectionView = {
    let flowLayout = UICollectionViewFlowLayout().then {
      $0.scrollDirection = .Horizontal
      $0.minimumInteritemSpacing = 0
      $0.minimumLineSpacing = 0
      $0.itemSize = self.size
    }
    return InfiniteCollectionView(frame: self.bounds, collectionViewLayout: flowLayout).then {
      $0.optimize()
      $0.pagingEnabled = true
      $0.showsHorizontalScrollIndicator = false
      $0.infiniteDataSource = self
      $0.infiniteDelegate = self
      $0.registerReusableCell(MovieListCarouselHeaderViewCell)
      $0.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI_2), 1, 0, 0)
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    [activityIndicatorView, collectionView].forEach { addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Private methods

  func prefetchImages() -> Observable<Bool> {
    return Observable.create { observer in
      let urls = self.items.map { $0.movie?.backdropUrl ?? $0.imageUrl }.flatMap { $0 }
      let prefetcher = ImagePrefetcher(urls: urls, optionsInfo: nil, progressBlock: nil, completionHandler: { _ in
        observer.onCompleted()
      })
      prefetcher.start()

      return AnonymousDisposable { prefetcher.stop() }
    }
  }
}

// MARK: - InfiniteCollectionViewDataSource

extension MovieListCarouselHeaderView: InfiniteCollectionViewDataSource {
  func cellForItemAtIndexPath(collectionView: UICollectionView, dequeueIndexPath: NSIndexPath,
    indexPath: NSIndexPath) -> UICollectionViewCell {
      let cell = collectionView
        .dequeueReusableCell(indexPath: indexPath, cellType: MovieListCarouselHeaderViewCell.self)
        .then { $0.configure(items[indexPath.row], interactor: interactor) }
      cells[indexPath] = cell
      return cell
  }

  func numberOfItems(collectionView: UICollectionView) -> Int {
    return items.count
  }
}

// MARK: - InfiniteCollectionViewDelegate

extension MovieListCarouselHeaderView: InfiniteCollectionViewDelegate {
  func didSelectCellAtIndexPath(collectionView: UICollectionView, indexPath: NSIndexPath) {
    items[indexPath.row].handler(cells[indexPath])
  }
}
