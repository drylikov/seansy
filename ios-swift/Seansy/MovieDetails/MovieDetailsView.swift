import Hue
import Kingfisher
import NSObject_Rx
import RxCocoa
import RxSwift
import SteviaLayout
import Sugar
import UIKit

final class MovieDetailsView: UIView {

  // MARK: Inputs

  let movie: Movie
  let presenter: MovieDetailsPresenter
  let interactor: MovieDetailsRouteInteractor

  // MARK: Public properties

  private(set) lazy var infoView: MovieInfoView = {
    return MovieInfoView(frame: self.bounds, movie: self.movie, presenter: self.presenter).then { $0.delegate = self }
  }()
  private(set) lazy var backdropImageView: MovieBackdropImageView = {
    return MovieBackdropImageView(
      frame: heightLens.to(self.height + 30, self.bounds),
      imageHeight: self.height - self.infoView.summaryHeight
    )
  }()

  // MARK: Private properties

  private var currentIndex: UInt = 0

  // Views
  private lazy var scrollView: UIScrollView = {
    return UIScrollView(frame: self.bounds).then {
      $0.optimize()
      $0.layer.mask = [.clearColor(), .blackColor()].gradient().then {
        let headerHeightRatio = (statusBarHeight + 44) / self.height
        $0.locations = [headerHeightRatio * 0.9, headerHeightRatio * 1.3]
        $0.frame = self.bounds
      }
      $0.addSubview(self.infoView)
    }
  }()
  private var progressView: SEAProgressView? = nil

  // MARK: Initialization

  init(movie: Movie, presenter: MovieDetailsPresenter, interactor: MovieDetailsRouteInteractor) {
    self.movie = movie
    self.presenter = presenter
    self.interactor = interactor
    super.init(frame: screenBounds)

    setUpBackdrop()
    [backdropImageView, progressView as UIView?].flatMap { $0 }.forEach { addSubview($0) }
    addSubview(scrollView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Private methods

  private func setUpBackdrop() {
    guard let backdropUrl = movie.backdropUrl ?? movie.posterUrl else {
      backdropImageView.updateImageViews(UIImage(.MovieBackdropPlaceholder))
      return
    }

    let cacheResult = ImageCache.defaultCache.isImageCachedForKey(Resource(downloadURL: backdropUrl).cacheKey)
    if cacheResult.cacheType != .Memory {
      progressView = SEAProgressView(frame: backdropImageView.frame)
        .then { $0.spinnerHeight = height - infoView.summaryHeight }
      infoView.hideTrailerButton()
    }

    KingfisherManager.sharedManager
      .retrieveImageWithURL(backdropUrl, progressBlock: { receivedSize, totalSize in
        let progress = CGFloat(receivedSize) / CGFloat(totalSize)
        if progress != 1.0 { self.progressView?.progress = progress }
      })
      .asDriver(onErrorJustReturn: nil)
      .flatMap { image -> Driver<BackdropColors> in
        self.backdropImageView.updateImageViews(image ?? UIImage(.MovieBackdropPlaceholder))

        if let colors = self.interactor.backdropColors[backdropUrl] {
          return Driver.just(colors)
        } else {
          return BackdropColors.getColors(image).doOnNext { self.interactor.setBackdropColors($0, url: backdropUrl) }
        }
      }
      .drive(
        onNext: { colors in
          let gradientImage = UIImage(gradientLayer: GradientType.Backdrop(colors[.Background]).gradientLayer)
          self.backdropImageView.gradientView.image = gradientImage
          self.backdropImageView.backgroundColor = colors[.Background]
          self.infoView.updateTextColors(colors[.Text])
        },
        onDisposed: {
          self.progressView?.performFinishAnimationWithDelay(0) { self.infoView.unhideTrailerButton() }
      })
      .addDisposableTo(rx_disposeBag)
  }
}

// MARK: - UIScrollViewDelegate

extension MovieDetailsView: UIScrollViewDelegate {
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let ratio = min(1, max(0,
      (infoView.contentInset.top + scrollView.contentOffset.y) / (infoView.contentInset.top - statusBarHeight - 44)))

    backdropImageView.alpha = 0.75 - (0.2 * ratio)
    backdropImageView.updateBlur(ratio)
    backdropImageView.top = -30 * ratio

    let titleViewProgress = (scrollView.contentOffset.y + statusBarHeight + 44) / infoView.titleLabel.bottom
    presenter.titleView.setProgress(min(1, max(0, titleViewProgress)))
  }

  func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint,
    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
      var ratio = (infoView.contentInset.top + targetContentOffset.memory.y) /
        (infoView.contentInset.top - statusBarHeight - 44)
      if ratio > 0 && ratio < 1 {
        switch velocity.y {
        case let y where y == 0: ratio = ratio > 0.5 ? 1 : 0
        case let y where y > 0: ratio = ratio > 0.1 ? 1 : 0
        default: ratio = ratio > 0.9 ? 1 : 0
        }
        targetContentOffset.memory.y = ratio == 1 ? -(statusBarHeight + 44) * 1.3 : -infoView.contentInset.top
      }

      infoView.activateState(ratio < 1 ? .Summary : .Detailed)
  }
}
