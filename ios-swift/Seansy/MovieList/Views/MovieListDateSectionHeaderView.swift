import Reusable
import Sugar
import UIKit

final class MovieListDateSectionHeaderView: UICollectionReusableView, Reusable {

  // MARK: Private properties

  private lazy var backgroundView: UIToolbar = {
    return UIToolbar(frame: self.bounds).then {
      $0.optimize()
      $0.barStyle = .Black
    }
  }()
  private lazy var textLabel: UILabel = {
    return UILabel(frame: CGRect(size: self.size, edgeInsets: UIEdgeInsets().left(10).right(10))).then {
      $0.optimize()
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(16)
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    optimize()
    backgroundView.addSubview(textLabel)
    addSubview(backgroundView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionReusableView

  override func prepareForReuse() {
    textLabel.text = nil
  }

  // MARK: Public methods

  func configure(title: String) {
    textLabel.text = title
  }
}
