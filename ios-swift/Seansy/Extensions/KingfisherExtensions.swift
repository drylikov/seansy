import Kingfisher
import RxSwift
import UIKit

extension KingfisherManager {
  func retrieveImageWithURL(URL: NSURL,
    optionsInfo: KingfisherOptionsInfo? = nil,
    progressBlock: DownloadProgressBlock? = nil) -> Observable<UIImage?> {
      return Observable.create { observer in
        let task = self.retrieveImageWithURL(URL, optionsInfo: optionsInfo, progressBlock: progressBlock,
          completionHandler: { image, error, cacheType, imageURL in
            if let error = error {
              observer.onError(error)
            } else {
              observer.onNext(image)
              observer.onCompleted()
            }
        })

        return AnonymousDisposable { task.cancel() }
      }
  }
}
