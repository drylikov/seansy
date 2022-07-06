import Kingfisher
import NSObject_Rx
import RxCocoa
import RxSwift
import UIKit

final class ShowtimeListCarousel: ShowtimeListCell {

  // MARK: ShowtimeListCell

  override var movie: Movie? {
    didSet {
      guard let imageUrl = movie?.backdropUrl ?? movie?.posterUrl else { return }

      KingfisherManager.sharedManager.retrieveImageWithURL(imageUrl)
        .asDriver(onErrorJustReturn: nil)
        .flatMap { BackdropColors.getColors($0) }
        .driveNext { self.color = $0[.Text] }
        .addDisposableTo(rx_disposeBag)
    }
  }
  override var cinema: Cinema? {
    didSet {
      guard let cinema = cinema else { return }

      titleLabel.text = cinema.name
      contentView.addSubview(titleLabel)
      collectionView.top = titleLabel.bottom
    }
  }

  // Views
  private lazy var titleLabel: UILabel = {
    return UILabel(frame: CGRect(x: 10, y: 10, width: self.width - 20, height: 22)).then {
      $0.optimize()
      $0.autoresizingMask = .FlexibleWidth
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(16)
    }
  }()

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    collectionView.frame = heightLens.to(64, bounds)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: ShowtimeListCell

  override func refresh() {
    var contentOffset = CGPoint.zero
    var hasNextShowtime = false
    let contentWidth = showtimes.reduce(showtimes.count > 1 ? CGFloat(-5) : CGFloat(0)) { contentWidth, showtime in
      if !hasNextShowtime && !showtime.passed {
        hasNextShowtime = true
        contentOffset.x = contentWidth + (showtimes.count > 1 ? 5 : 0)
      }
      return contentWidth + self.itemCellSize(showtime).width + 5
    }

    if (!hasNextShowtime && contentWidth > width - 20) || contentOffset.x > contentWidth - width + 20 {
      contentOffset.x = contentWidth - width + 20
    }

    collectionView.contentOffset = contentOffset
    collectionView.reloadData()
  }

  // MARK: UITableViewCell

  override func prepareForReuse() {
    super.prepareForReuse()

    titleLabel.removeFromSuperview()
    titleLabel.text = nil
  }
}
