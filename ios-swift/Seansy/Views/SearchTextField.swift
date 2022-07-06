import Hue
import RxCocoa
import RxSwift
import Sugar
import Tactile
import UIKit

final class SearchTextField: UITextField {

  // MARK: Public properties

  lazy var textObservable: Observable<String> = {
    return Observable
      .create { observer in
        self.textSubject.map { $0.trim() }.subscribe(observer)
        self.rx_text.map { $0.trim() }.subscribe(observer)

        return NopDisposable.instance
      }
      .distinctUntilChanged()
  }()

  // MARK: Private properties

  private lazy var textSubject = PublishSubject<String>()

  // MARK: UITextField

  override var text: String? {
    didSet { self.textSubject.onNext(text ?? "") }
  }

  override var placeholder: String? {
    get { return attributedPlaceholder?.string }
    set {
      attributedPlaceholder = newValue.flatMap {
        NSAttributedString(string: $0, attributes: [ NSForegroundColorAttributeName: UIColor.whiteColor().alpha(0.5) ])
      }
    }
  }

  // MARK: Initialization

  init() {
    super.init(frame: CGRect(width: .max, height: 28))

    optimize()
    backgroundColor = UIColor.blackColor().alpha(0.5)
    textColor = .whiteColor()
    textAlignment = .Left
    font = .regularFontOfSize(14)
    tintColor = UIColor.whiteColor().alpha(0.5)
    returnKeyType = .Search
    borderStyle = .RoundedRect
    leftView = UIImageView(frame: CGRect(width: height, height: height)).then {
      $0.image = UIImage(.SearchIcon).icon
      $0.contentMode = .Center
      $0.tintColor = UIColor.whiteColor().alpha(0.5)
    }
    leftViewMode = .Always
    rightView = UIButton(frame: CGRect(width: height, height: height)).then {
      $0.setImage(UIImage(.ClearIcon).icon, forState: .Normal)
      $0.tintColor = UIColor.whiteColor().alpha(0.5)
      $0.on(.TouchUpInside) { _ in self.text = "" }
    }
    rightViewMode = .WhileEditing
    delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - UITextFieldDelegate

extension SearchTextField: UITextFieldDelegate {
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }
}
