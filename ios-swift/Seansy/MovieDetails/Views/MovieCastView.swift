import NSObject_Rx
import NYTPhotoViewer
import Reusable
import RxCocoa
import RxSwift
import Sugar
import UIKit

final class MovieCastView: MovieInfoCarousel<MovieCrewMember>, NYTPhotosViewControllerDelegate {

  // MARK: Private properties

  private let photos: [Photo?]

  // MARK: Initialization

  override init(frame: CGRect, viewModel: MovieInfoCarouselModel<MovieCrewMember>, presenter: MovieDetailsPresenter) {
    photos = viewModel.data.map { actor in
      actor.photoUrl.flatMap { Photo(url: $0, name: actor.name) }
    }
    super.init(frame: frame, viewModel: viewModel, presenter: presenter)

    collectionView.registerReusableCell(MovieActorCell)
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
    -> UICollectionViewCell {
      return collectionView
        .dequeueReusableCell(indexPath: indexPath, cellType: MovieActorCell.self)
        .then { $0.configure(viewModel.data[indexPath.row], photo: photos[indexPath.row]) }
  }

  // MARK: UICollectionViewDelegate

  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let stillsViewController = NYTPhotosViewController(photos: photos.flatMap { $0 },
      initialPhoto: photos[indexPath.row]).then { $0.delegate = self }
    presenter.presentImages(stillsViewController)
    photos.flatMap { $0 }.filter { $0.image == nil }.forEach { photo in
      photo.getImage
        .driveNext { _ in stillsViewController.updateImageForPhoto(photo) }
        .addDisposableTo(rx_disposeBag)
    }
  }

  func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return viewModel.data[indexPath.row].photoUrl != nil
  }

  // MARK: NYTPhotosViewControllerDelegate

  func photosViewController(photosViewController: NYTPhotosViewController, referenceViewForPhoto photo: NYTPhoto)
    -> UIView? {
      if let photo = photo as? Photo, row = viewModel.data.map({ $0.photoUrl ?? ""}).indexOf(photo.url.absoluteString),
        cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as? MovieActorCell {
          return cell.photoImageView
      }

      return nil
  }

  func photosViewControllerDidDismiss(photosViewController: NYTPhotosViewController) {
    UIApplication.sharedApplication().statusBarHidden = false
  }
}
