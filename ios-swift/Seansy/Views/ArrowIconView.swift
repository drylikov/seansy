import Sugar
import UIKit

final class ArrowIconView: UIView {

  // MARK: Public types

  enum Orientation {
    case Horizontal, Vertical
  }

  enum Direction {
    case Up, Left, Down, Right
  }

  // MARK: Public properties

  var orientation: Orientation! {
    didSet {
      [topArrowPart, bottomArrowPart].forEach { $0.hidden = orientation == .Horizontal }
      [leftArrowPart, rightArrowPart].forEach { $0.hidden = orientation == .Vertical }
    }
  }
  var color: UIColor {
    didSet {
      [topArrowPart, leftArrowPart, bottomArrowPart, rightArrowPart].forEach { $0.backgroundColor = color }
    }
  }

  // MARK: Private properties

  private lazy var topArrowPart: UIView = {
    return self.arrowPart(origin: .zero, orientation: .Vertical)
  }()
  private lazy var leftArrowPart: UIView = {
    return self.arrowPart(origin: .zero, orientation: .Horizontal)
  }()
  private lazy var bottomArrowPart: UIView = {
    return self.arrowPart(origin: CGPoint(x: 0, y: self.height / 2 - self.width), orientation: .Vertical)
  }()
  private lazy var rightArrowPart: UIView = {
    return self.arrowPart(origin: CGPoint(x: self.width / 2 - self.height, y: 0), orientation: .Horizontal)
  }()

  // MARK: Private constants

  private let horizontalCurvature = CGFloat(30.0 * M_PI / 180.0)
  private let verticalCurvature = CGFloat(45.0 * M_PI / 180.0)

  // MARK: Initialization

  init(frame: CGRect, orientation: Orientation, color: UIColor = .whiteColor()) {
    self.orientation = orientation
    self.color = color
    super.init(frame: frame)

    alpha = 0.75
    [topArrowPart, leftArrowPart, bottomArrowPart, rightArrowPart].forEach { addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func point(direction: Direction, animated: Bool = false) {
    if animated {
      UIView.animateWithDuration(0.2) {
        self.point(direction)
      }
    } else {
      point(direction)
    }
  }

  // MARK: Private methods

  private func arrowPart(origin origin: CGPoint, orientation: Orientation) -> UIView {
    return UIView(frame: CGRect(origin: origin, size: .zero)).then {
      $0.optimize()
      $0.backgroundColor = color
      $0.size = CGSize(
        width: orientation == .Horizontal ? width / 2 + height : width,
        height: orientation == .Horizontal ? height : height / 2 + width
      )
      $0.layer.allowsEdgeAntialiasing = true
      $0.layer.cornerRadius = (orientation == .Horizontal ? height : width) / 2
      $0.hidden = self.orientation != orientation
    }
  }

  private func point(direction: Direction) {
    switch direction {
    case .Up, .Down:
      leftArrowPart.transform = CGAffineTransformMakeRotation(horizontalCurvature * (direction == .Up ? -1 : 1))
      rightArrowPart.transform = CGAffineTransformMakeRotation(horizontalCurvature * (direction == .Up ? 1 : -1))
    case .Left, .Right:
      topArrowPart.transform = CGAffineTransformMakeRotation(verticalCurvature * (direction == .Left ? 1 : -1))
      bottomArrowPart.transform = CGAffineTransformMakeRotation(verticalCurvature * (direction == .Left ? -1 : 1))
    }
  }
}
