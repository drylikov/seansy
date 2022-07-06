import Reusable
import RxDataSources
import UIKit

struct CinemaSummaryListSection {
  var cinemas: [Cinema]
  let title: String
}

extension CinemaSummaryListSection: AnimatableSectionModelType {
  typealias Item = Cinema
  typealias Identity = String

  var identity: String { return title }
  var items: [Item] { return cinemas }

  init(original: CinemaSummaryListSection, items: [Item]) {
    self = original
    cinemas = items
  }
}

// MARK: -

final class CinemaSummaryListCell: UITableViewCell, Reusable, Transitionable {

  // MARK: Private properties

  private var factory: CinemaSummaryViewFactory!

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    size = CGSize(width: screenWidth, height: CinemaSummaryViewFactory.height)
    factory = CinemaSummaryViewFactory(bounds: sizeLens.to(size, .zero))

    optimize()
    backgroundColor = .blackColor()
    backgroundView = factory.imageView
    selectionStyle = .None
    factory.subviews.forEach { addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewCell

  override func prepareForReuse() { factory.prepareForReuse() }

  // MARK: Transitionable

  func setInfoAlpha(alpha: CGFloat) { factory.setInfoAlpha(alpha) }

  // MARK: Public methods

  func configure(cinema: Cinema) { factory.configure(cinema) }
}

// MARK: -

final class CinemaSummaryListView: SummaryListView {
  override init() {
    super.init()

    rowHeight = CinemaSummaryViewFactory.height
    registerReusableCell(CinemaSummaryListCell)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
