import Reusable
import STZPopupView
import Sugar
import UIKit

final class MovieReviewsView: MovieInfoCarousel<MoviePressReview> {

  // MARK: Initialization

  override init(frame: CGRect, viewModel: MovieInfoCarouselModel<MoviePressReview>, presenter: MovieDetailsPresenter) {
    super.init(frame: frame, viewModel: viewModel, presenter: presenter)
    collectionView.registerReusableCell(MovieReviewCell)
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
    -> UICollectionViewCell {
      return collectionView
        .dequeueReusableCell(indexPath: indexPath, cellType: MovieReviewCell.self)
        .then { $0.configure(viewModel.data[indexPath.row]) }
  }

  // MARK: UICollectionViewDelegate

  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let review = viewModel.data[indexPath.row]

    let popupView = UIView(frame: CGRect(width: screenWidth - 40, height: 0)).then {
      $0.optimize()
      $0.backgroundColor = .whiteColor()
    }
    let reviewTextView = UILabel(frame: CGRect(x: 10, y: 10, width: popupView.width - 20, height: 0)).then {
      $0.optimize()
      $0.textColor = .blackColor()
      $0.font = .regularFontOfSize(14)
      $0.text = review.text
      $0.sizeToFitInHeight(0)
      popupView.height = $0.height + 20
    }
    popupView.addSubview(reviewTextView)

    let popupConfig = STZPopupViewConfig()
    popupConfig.dismissTouchBackground = true
    popupConfig.cornerRadius = 10

    presenter.presentPopupView(popupView, config: popupConfig)
  }
}
