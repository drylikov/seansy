import Sugar
import Reusable
import UIKit

final class MovieInfoCarouselModel<T> {

  // MARK: Inputs

  var data: [T]
  let description: String
  let itemHeight: CGFloat
  let itemWidth: CGFloat?

  // MARK: Initialization

  init(data: [T], description: String, itemHeight: CGFloat = 100, itemWidth: CGFloat? = nil) {
    self.data = data
    self.description = description
    self.itemHeight = itemHeight
    self.itemWidth = itemWidth
  }
}

// MARK: -

class MovieInfoCarousel<T>: UIView, Labeled, UICollectionViewDataSource, UICollectionViewDelegate {

  // MARK: Inputs

  let viewModel: MovieInfoCarouselModel<T>
  let presenter: MovieDetailsPresenter

  // MARK: Public properties

  private(set) lazy var descriptionLabel: MovieInfoLabel = {
    return MovieInfoLabel(frame: CGRect(x: 10, y: 0, width: self.width - 20, height: 0)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .semiboldFontOfSize(16)
      $0.text = self.viewModel.description + ":"
      $0.sizeToFitInHeight(0)
    }
  }()
  private(set) lazy var collectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout().then {
      $0.scrollDirection = .Horizontal
      $0.minimumInteritemSpacing = 2
      $0.minimumLineSpacing = 2
      if let itemWidth = self.viewModel.itemWidth {
        $0.itemSize = CGSize(width: itemWidth, height: self.viewModel.itemHeight)
      }
    }
    return UICollectionView(
      frame: CGRect(x: 0, y: self.descriptionLabel.bottom + 10, width: self.width, height: self.viewModel.itemHeight),
      collectionViewLayout: flowLayout).then {
        $0.optimize()
        $0.backgroundColor = .clearColor()
        $0.showsHorizontalScrollIndicator = false
        $0.dataSource = self
        $0.delegate = self
    }
  }()

  // MARK: Initialization

  init(frame: CGRect, viewModel: MovieInfoCarouselModel<T>, presenter: MovieDetailsPresenter) {
    self.viewModel = viewModel
    self.presenter = presenter
    super.init(frame: frame)

    addSubview(descriptionLabel)
    addSubview(collectionView)

    height = collectionView.bottom
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionViewDataSource

  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 1 }

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewModel.data.count
  }

  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
    -> UICollectionViewCell { return UICollectionViewCell() }
}
