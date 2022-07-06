import Foundation
import NYTPhotoViewer

final class Poster: NSObject, NYTPhoto {

  // MARK: Inputs

  let image: UIImage?

  // MARK: NYTPhoto

  let imageData: NSData? = nil
  let placeholderImage: UIImage? = nil
  let attributedCaptionTitle: NSAttributedString? = nil
  let attributedCaptionSummary: NSAttributedString? = nil
  let attributedCaptionCredit: NSAttributedString? = nil

  // MARK: Initialization

  init(image: UIImage) {
    self.image = image
    super.init()
  }
}
