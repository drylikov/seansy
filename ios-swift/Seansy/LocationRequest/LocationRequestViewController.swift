import Hue
import Proposer
import SteviaLayout
import Tactile
import UIKit
import VideoSplashKit

private final class BorderedButton: UIButton {

  // MARK: UIButton

  override var highlighted: Bool {
    didSet { backgroundColor = highlighted ? .whiteColor() : UIColor.whiteColor().alpha(0.1) }
  }

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.whiteColor().alpha(0.1)
    titleLabel?.font = .regularFontOfSize(20)
    setTitleColor(.whiteColor(), forState: .Highlighted)
    setTitleColor(UIColor.clearColor().alpha(0.5), forState: .Highlighted)
    layer.borderWidth = 1.0
    layer.borderColor = UIColor.whiteColor().CGColor
    layer.cornerRadius = 5.0
    layer.masksToBounds = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

final class LocationRequestViewController: VideoSplashViewController {

  // MARK: Inputs

  let interactor: LocationRequestInteractor

  // MARK: Private properties

  private let titleLabel = UILabel().then {
    $0.text = "Нам нужно ваше местоположение, чтобы определить ближайшие кинотеатры"
    $0.textColor = .whiteColor()
    $0.font = .regularFontOfSize(20)
    $0.textAlignment = .Center
    $0.numberOfLines = 0
  }
  private let locationIconImageView = UIImageView(image: UIImage(.LocationArrowIcon).icon)
    .then { $0.tintColor = .whiteColor() }
  private lazy var pulseAnimationLayer: PulseAnimationLayer = {
    return PulseAnimationLayer(radius: 150.0, position: self.view.center)
  }()
  private lazy var skipButton: UIButton = {
    return BorderedButton().then {
      $0.setTitle("Пропустить", forState: .Normal)
      $0.on(.TouchUpInside) { _ in
        log.info("➡️ User skipped location permission request")
        self.interactor.updateCity(byIp: true)
      }
    }
  }()
  private lazy var proposeButton: UIButton = {
    return BorderedButton().then {
      $0.setTitle("Дать доступ", forState: .Normal)
      $0.on(.TouchUpInside) { _ in
        proposeToAccess(.Location(.WhenInUse),
          agreed: {
            log.info("✅ User gave permission to access their location")
            self.interactor.updateCity(byIp: false)
          },
          rejected: {
            log.info("❌ User rejected to give permission to access their location")
            self.interactor.updateCity(byIp: true)
        })
      }
    }
  }()

  // MARK: Initialization

  init(interactor: LocationRequestInteractor) {
    self.interactor = interactor
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.sv(titleLabel, locationIconImageView, proposeButton, skipButton)
    view.layout(
      30,
      |-30-titleLabel-30-|,
      "",
      |-30-proposeButton-30-| ~ 50,
      10,
      |-30-skipButton-30-| ~ 50,
      30
    )
    locationIconImageView.centerInContainer()
    view.layer.insertSublayer(pulseAnimationLayer, below: locationIconImageView.layer)

    videoFrame = view.bounds
    fillMode = .ResizeAspectFill
    alwaysRepeat = true
    sound = false
    duration = 13.0
    alpha = 0.7
    backgroundColor = .blackColor()
    contentURL = .fileURLWithPath(NSBundle.mainBundle().pathForResource("Almaty", ofType: "mp4")!)
    restartForeground = true
  }
}
