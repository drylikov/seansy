import Reusable
import Sugar
import UIKit

final class ShowtimeListItemCell: UICollectionViewCell, Reusable {

  // MARK: Public properties

  var color: UIColor = .whiteColor() {
    didSet { updateView() }
  }
  var reversed = false {
    didSet { updateView() }
  }
  private(set) lazy var timeLabel: UILabel = {
    return UILabel(frame: self.bounds).then {
      $0.optimize()
      $0.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
      $0.textColor = self.color
      $0.textAlignment = .Center
      $0.numberOfLines = 0
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    layer.borderWidth = 1
    layer.borderColor = color.CGColor
    layer.cornerRadius = 5
    clipsToBounds = true

    contentView.addSubview(timeLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionViewCell

  override func prepareForReuse() {
    timeLabel.text = nil
    alpha = 1
    reversed = false
  }

  // MARK: Public methods

  func configure(showtime: Showtime, cinema: Cinema? = nil) {
    timeLabel.attributedText = showtime.summaryString(cinema)
    if showtime.passed { alpha = 0.3 }
  }

  // MARK: Private methods

  private func updateView() {
    timeLabel.textColor = reversed ? .primaryColor() : color
    layer.borderColor = reversed ? nil : color.CGColor
    layer.backgroundColor = reversed ? color.CGColor : nil
  }
}
