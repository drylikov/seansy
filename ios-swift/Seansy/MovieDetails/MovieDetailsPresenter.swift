import AVKit
import NSObject_Rx
import NYTPhotoViewer
import RxCocoa
import RxSwift
import STZPopupView
import UIKit
import XCDYouTubeKit

final class TrailerViewController: AVPlayerViewController {
  override func viewWillDisappear(animated: Bool) {
    showsPlaybackControls = false
    super.viewWillDisappear(animated)
  }
}

// MARK: -

final class MovieDetailsPresenter: NSObject {

  // MARK: Inputs

  var viewController: UIViewController!

  // MARK: Private properties

  private var videoPlayerViewController: XCDYouTubeVideoPlayerViewController?
  private var trailerObservable: Observable<Bool>?

  // MARK: Public properties

  var titleView: ScrollingNavigationBarTitleView {
    return viewController.navigationItem.titleView! as! ScrollingNavigationBarTitleView
  }

  // MARK: Public methods

  func playTrailer(youtubeId: String) -> Observable<Bool> {
    if let trailerObservable = trailerObservable { return trailerObservable }

    XCDYouTubeLogger.setLogHandler { _, _, _, _, _ in }

    let observable = Observable<Bool>
      .create { observer in
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(youtubeId) { [weak self]
          (video: XCDYouTubeVideo?, error: NSError?) in
          guard let `self` = self else { return }

          if let error = error {
            log.error("Failed to play trailer: \(error.localizedDescription)")
            self.viewController.presentError(title: "Произошла ошибка", subtitle: error.localizedDescription)
          } else if let streamURL = (video?.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
            video?.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ??
            video?.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] ??
            video?.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue]) {
              let playerViewController = TrailerViewController().then {
                $0.player = AVPlayer(URL: streamURL)
                $0.player?.rx_observe(AVPlayerItemStatus.self, "status")
                  .subscribeNext { status in
                    if status == .ReadyToPlay {
                      UIDevice.currentDevice()
                        .setValue(UIInterfaceOrientation.LandscapeRight.rawValue, forKey: "orientation")
                    }
                  }
                  .addDisposableTo(self.rx_disposeBag)
                $0.player?.play()
              }

              NSNotificationCenter.defaultCenter()
                .rx_notification(AVPlayerItemDidPlayToEndTimeNotification,
                  object: playerViewController.player!.currentItem)
                .subscribeNext { _ in playerViewController.dismissViewControllerAnimated(true, completion: nil) }
                .addDisposableTo(self.rx_disposeBag)

              observer.onNext(true)
              observer.onCompleted()

              return self.viewController
                .presentViewController(playerViewController, animated: true, completion: nil)
          }

          observer.onNext(false)
          observer.onCompleted()
        }

        return NopDisposable.instance
      }
      .doOnCompleted { self.trailerObservable = nil }.shareReplay(1)
    trailerObservable = observable

    return observable
  }

  func presentImages(viewController: NYTPhotosViewController) {
    UIApplication.sharedApplication().statusBarHidden = true
    self.viewController.presentViewController(viewController, animated: true, completion: nil)
  }

  func presentPopupView(popupView: UIView, config: STZPopupViewConfig) {
    viewController.presentPopupView(popupView, config: config)
  }
}
