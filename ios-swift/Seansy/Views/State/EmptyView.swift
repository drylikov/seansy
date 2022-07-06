import SteviaLayout
import UIKit

final class EmptyView: ConfusedVincentVegaView {
  init(frame: CGRect) {
    super.init(frame: frame, title: "Ничего не найдено :(")

    layout(
      "",
      |-10-titleLabel-10-|,
      20,
      gifView.centerHorizontally().size(200),
      0
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
