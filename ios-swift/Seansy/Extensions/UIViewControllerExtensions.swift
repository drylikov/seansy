import Whisper
import UIKit

extension UIViewController {
  func presentError(title title: String, subtitle: String? = nil) {
    if navigationController == nil { return }

    ShoutView()
      .then {
        $0.titleLabel.textColor = .whiteColor()
        $0.subtitleLabel.textColor = .whiteColor()
        $0.backgroundView.backgroundColor = .flatRedColor()
      }
      .craft(Announcement(title: title, subtitle: subtitle, image: nil, duration: 4.0), to: self) {}
  }
}
