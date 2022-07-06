import Kingfisher
import Reusable
import RxDataSources
import Sugar
import UIKit

final class RecentSearchesViewCell: UICollectionViewCell, Reusable {

  // MARK: Private properties

  private lazy var imageView: UIImageView = {
    return UIImageView(frame: CGRect(x: 0, y: 10, width: self.width, height: self.width)).then {
      $0.optimize()
      $0.image = UIImage(.SearchDefaultIconBig).icon
      $0.tintColor = .accentColor()
      $0.contentMode = .ScaleAspectFill
      $0.layer.cornerRadius = self.width / 2
    }
  }()
  private lazy var textLabel: UILabel = {
    return UILabel(frame: CGRect(x: 0, y: self.imageView.bottom + 5, width: self.width, height: 0)).then {
      $0.optimize()
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(13)
      $0.textAlignment = .Center
      $0.numberOfLines = 2
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    [imageView, textLabel].forEach { contentView.addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionView

  override func prepareForReuse() {
    imageView.image = UIImage(.SearchDefaultIconBig).icon
    textLabel.text = nil
  }

  // MARK: Public methods

  func configure(item: SearchItem) {
    textLabel.text = item.query
    textLabel.sizeToFitInHeight(height - imageView.bottom - 15)
    let placeholderImage = UIImage(item.bigAsset).icon
    if let imageUrl = item.imageUrl {
      let imageCached = ImageCache.defaultCache.cachedImageExistsforURL(imageUrl)
      imageView.kf_setImageWithURL(
        imageUrl,
        placeholderImage: imageCached ? nil : placeholderImage,
        optionsInfo: [.Transition(ImageTransition.Fade(0.3))]
      )
    } else {
      imageView.image = placeholderImage
    }
  }
}

// MARK: -

final class RecentSearchesView: UICollectionView {

  // MARK: Public properties

  let sectionedDataSource = RxCollectionViewSectionedReloadDataSource<SearchItemsSection>()

  // MARK: Initialization

  init(frame: CGRect) {
    let flowLayout = UICollectionViewFlowLayout().then {
      $0.scrollDirection = .Horizontal
      $0.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
      $0.minimumInteritemSpacing = 20
      $0.minimumLineSpacing = 20
      $0.itemSize = CGSize(width: frame.height / 1.9, height: frame.height)
    }
    super.init(frame: frame, collectionViewLayout: flowLayout)

    optimize()
    backgroundColor = .clearColor()
    showsHorizontalScrollIndicator = false
    registerReusableCell(RecentSearchesViewCell)
    sectionedDataSource.cellFactory = { _, collectionView, indexPath, item in
      return collectionView
        .dequeueReusableCell(indexPath: indexPath, cellType: RecentSearchesViewCell.self)
        .then { $0.configure(item) }
    }
    dataSource = sectionedDataSource
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
