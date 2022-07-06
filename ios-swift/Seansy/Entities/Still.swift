import Foundation
import ImageScout
import Kingfisher
import NYTPhotoViewer
import RxCocoa
import RxSwift
import Sugar

final class Still: NSObject, NYTPhoto {

  // MARK: Inputs

  let url: NSURL

  // MARK: Public properties

  private(set) var image: UIImage?
  private(set) lazy var size: CGSize = {
    return self.image?.size ?? .zero
  }()

  var getSize: Driver<CGSize> {
    return Observable
      .create { observer in
        dispatch(queue: .Background) {
          if let cachedImage = KingfisherManager.sharedManager.cache
            .retrieveImageInDiskCacheForKey(self.url.absoluteString) {
              self.image = cachedImage
              self.size = cachedImage.size
              observer.onNext(self.size)
              observer.onCompleted()
          } else {
            self.scout.scoutImageWithURI(self.url.absoluteString) { error, size, type in
              if let error = error { log.error("Failed to get size for still: \(error)") }

              self.size = size
              observer.onNext(size)
              observer.onCompleted()
            }
          }
        }

        return NopDisposable.instance
      }
      .asDriver(onErrorJustReturn: .zero)
  }

  var getImage: Driver<UIImage?> {
    if let imageDriver = imageDriver {
      return imageDriver
    } else if let image = image {
      return Driver.just(image)
    }

    imageDriver = KingfisherManager.sharedManager
      .retrieveImageWithURL(url)
      .doOnNext { self.image = $0 }
      .shareReplay(1)
      .asDriver(onErrorJustReturn: nil)

    return imageDriver!
  }

  // MARK: NYTPhoto

  let imageData: NSData? = nil
  let placeholderImage: UIImage? = nil
  let attributedCaptionTitle: NSAttributedString? = nil
  let attributedCaptionSummary: NSAttributedString? = nil
  let attributedCaptionCredit: NSAttributedString? = nil

  // MARK: Private properties

  private var imageDriver: Driver<UIImage?>?
  private lazy var scout = ImageScout()

  // MARK: Initialization

  init(url: NSURL) {
    self.url = url
    super.init()
  }
}
