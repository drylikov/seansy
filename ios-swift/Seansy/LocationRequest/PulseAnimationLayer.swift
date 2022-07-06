import Sugar
import UIKit

final class PulseAnimationLayer: CALayer {

  // MARK: Inputs

  let repetitions: Float

  // MARK: Private properties

  private lazy var animationGroup: CAAnimationGroup = {
    return CAAnimationGroup().then {
      $0.duration = self.animationDuration
      $0.repeatCount = self.repetitions
      $0.removedOnCompletion = false
      $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
      $0.animations = [self.scaleAnimation, self.opacityAnimation]
    }
  }()
  private lazy var scaleAnimation: CABasicAnimation = {
    return CABasicAnimation(keyPath: "transform.scale.xy").then {
      $0.fromValue = NSNumber(float: 0.0)
      $0.toValue = NSNumber(float: 1.0)
      $0.duration = self.animationDuration
    }
  }()
  private lazy var opacityAnimation: CAKeyframeAnimation = {
    return CAKeyframeAnimation(keyPath: "opacity").then {
      $0.duration = self.animationDuration
      $0.values = [0.45, 0.8, 0]
      $0.keyTimes = [0, 0.2, 1]
      $0.removedOnCompletion = false
    }
  }()

  // MARK: Private constants

  private let animationDuration: NSTimeInterval = 3.0

  // MARK: Initialization

  init(repetitions: Float = .infinity, radius: CGFloat, position: CGPoint) {
    self.repetitions = repetitions
    super.init()

    frame = CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2)
    cornerRadius = radius
    opacity = 0.0
    contentsScale = UIScreen.mainScreen().scale
    backgroundColor = UIColor.whiteColor().CGColor
    addAnimation(animationGroup, forKey: "pulse")
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
