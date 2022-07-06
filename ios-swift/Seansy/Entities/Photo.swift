import Foundation
import ImageScout
import Kingfisher
import NYTPhotoViewer
import RxCocoa
import RxSwift

final class Photo: NSObject, NYTPhoto {

  // MARK: Inputs

  let url: NSURL

  // MARK: Public properties

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

  private(set) var image: UIImage?
  let attributedCaptionTitle: NSAttributedString?
  let imageData: NSData? = nil
  let placeholderImage: UIImage? = nil
  let attributedCaptionSummary: NSAttributedString? = nil
  let attributedCaptionCredit: NSAttributedString? = nil

  // MARK: Private properties

  private var imageDriver: Driver<UIImage?>?

  // MARK: Initialization

  init(url: NSURL, name: String) {
    self.url = url
    attributedCaptionTitle = NSAttributedString(string: name,
      attributes: [
        NSFontAttributeName: UIFont.regularFontOfSize(20),
        NSForegroundColorAttributeName: UIColor.whiteColor()
      ])
    super.init()
  }
}
