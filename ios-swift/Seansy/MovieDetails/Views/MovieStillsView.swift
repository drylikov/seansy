import NSObject_Rx
import NYTPhotoViewer
import Reusable
import RxCocoa
import RxSwift
import Sugar
import UIKit

final class MovieStillsView: MovieInfoCarousel<Still>, NYTPhotosViewControllerDelegate {

  // MARK: Initialization

  override init(frame: CGRect, viewModel: MovieInfoCarouselModel<Still>, presenter: MovieDetailsPresenter) {
    super.init(frame: frame, viewModel: viewModel, presenter: presenter)

    collectionView.registerReusableCell(MovieStillCell)
    collectionView.userInteractionEnabled = false
    viewModel.data.map { $0.getSize }.toObservable().merge()
      .doOnCompleted { _ in
        self.collectionView.userInteractionEnabled = true
        UIView.animateWithDuration(0.2) { self.collectionView.collectionViewLayout.invalidateLayout() }
      }
      .flatMap { _ in self.viewModel.data.map { $0.getImage }.toObservable().merge() }
      .subscribeNext { _ in self.collectionView.reloadData() }
      .addDisposableTo(rx_disposeBag)
  }

  // MARK: UICollectionViewDataSource

  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
      let size = viewModel.data[indexPath.row].size
      if size == .zero {
        return CGSize(width: collectionView.height, height: collectionView.height)
      } else {
        let ratio = collectionView.height / size.height
        return CGSize(width: size.width * ratio, height: collectionView.height)
      }
  }

  override func collectionView(collectionView: UICollectionView,
    cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      return collectionView.dequeueReusableCell(indexPath: indexPath, cellType: MovieStillCell.self).then {
        let still = viewModel.data[indexPath.row]
        if let image = still.image { $0.setImage(image) }
      }
  }

  // MARK: UICollectionViewDelegate

  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let stillsViewController = NYTPhotosViewController(photos: viewModel.data,
      initialPhoto: viewModel.data[indexPath.row]).then { $0.delegate = self }
    presenter.presentImages(stillsViewController)
    viewModel.data.filter { $0.image == nil }.forEach { still in
      still.getImage
        .driveNext { _ in stillsViewController.updateImageForPhoto(still) }
        .addDisposableTo(rx_disposeBag)
    }
  }

  // MARK: NYTPhotosViewControllerDelegate

  func photosViewController(photosViewController: NYTPhotosViewController, referenceViewForPhoto photo: NYTPhoto)
    -> UIView? {
      if let still = photo as? Still, row = viewModel.data.indexOf(still) {
        return collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
      }

      return nil
  }

  func photosViewControllerDidDismiss(photosViewController: NYTPhotosViewController) {
    UIApplication.sharedApplication().statusBarHidden = false
  }
}
