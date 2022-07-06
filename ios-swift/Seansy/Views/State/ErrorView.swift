import SteviaLayout
import Sugar
import Tactile
import UIKit

final class ErrorView: ConfusedVincentVegaView {

  // MARK: Private properties

  private let reloadButton = UIButton().then {
    $0.optimize()
    $0.tintColor = .whiteColor()
    $0.setImage(UIImage(.ReloadIcon).icon, forState: .Normal)
  }

  // MARK: Initialization

  init(frame: CGRect, reloadHandler: () -> Void) {
    super.init(frame: frame, title: "Произошла ошибка при загрузке данных")

    sv(reloadButton)
    layout(
      "",
      |-10-titleLabel-10-|,
      20,
      reloadButton.centerHorizontally().size(44),
      20,
      gifView.centerHorizontally().size(200),
      0
    )
    reloadButton.on(.TouchUpInside) { _ in reloadHandler() }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
