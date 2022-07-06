import UIKit

class MovieInfoList: UIView, Labeled {

  // MARK: Inputs

  let descriptionString: String
  let textString: String

  // MARK: Public properties

  private(set) lazy var descriptionLabel: MovieInfoLabel = {
    return MovieInfoLabel(frame: CGRect(width: self.width, height: 0)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .semiboldFontOfSize(16)
      $0.text = self.descriptionString
      $0.sizeToFitInHeight(0)
    }
  }()
  private(set) lazy var textLabel: MovieInfoLabel = {
    return MovieInfoLabel(frame: CGRect(x: 0, y: self.descriptionLabel.bottom + 5, width: self.width, height: 0)).then {
      $0.optimize()
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(16)
      $0.text = self.textString
      $0.sizeToFitInHeight(0)
    }
  }()

  // MARK: Initialization

  init(frame: CGRect, description: String, text: String) {
    descriptionString = description
    textString = text
    super.init(frame: frame)

    [descriptionLabel, textLabel].forEach { addSubview($0) }
    height = textLabel.bottom
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
