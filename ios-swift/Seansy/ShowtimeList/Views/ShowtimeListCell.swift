import AMPopTip
import Hue
import Reusable
import Sugar
import Tactile
import UIKit

protocol ShowtimeCellDelegate: NSObjectProtocol {
  var visiblePopTip: AMPopTip? { get set }
  func openShowtime(showtime: Showtime)
  func buyTicketForShowtime(ticketonUrl ticketonUrl: NSURL)
}

private final class PopTipButton: UIButton {

  // MARK: UIButton

  override var highlighted: Bool {
    didSet { backgroundColor = highlighted ? UIColor.primaryColor().alpha(0.3) : UIColor.primaryColor().alpha(0.2) }
  }

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    optimize()
    backgroundColor = UIColor.primaryColor().alpha(0.2)
    titleLabel?.font = .regularFontOfSize(16)
    setTitleColor(.primaryColor(), forState: .Normal)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

private final class PopTipView: UIView {

  // MARK: Private properties

  private lazy var textLabel: UILabel = {
    return UILabel(frame: CGRect(x: 6, y: 6, width: 200, height: 0)).then {
      $0.optimize()
      $0.numberOfLines = 0
    }
  }()
  private lazy var ticketButton: PopTipButton = {
    return PopTipButton(frame: CGRect(x: 0, y: self.textLabel.bottom + 6, width: 212, height: 44))
      .then { $0.setTitle("Купить билет", forState: .Normal) }
  }()

  // MARK: Initialization

  init(showtime: Showtime, movie: Movie, buttonClosure: (NSURL -> Void)?) {
    super.init(frame: .zero)

    textLabel.attributedText = showtime.detailsString(movie)
    textLabel.size = textLabel.attributedText?.size(CGSize(width: 200, height: CGFloat.infinity)) ?? .zero
    addSubview(textLabel)

    if let ticketonUrl = showtime.ticketonUrl {
      ticketButton.on(.TouchUpInside) { _ in buttonClosure?(ticketonUrl) }
      addSubview(ticketButton)
      frame = CGRect(width: 212, height: ticketButton.bottom)
    } else {
      frame = CGRect(width: 212, height: textLabel.bottom + 6)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

class ShowtimeListCell: UITableViewCell, Reusable {

  // MARK: Public properties

  var movie: Movie?
  var cinema: Cinema?
  var showtimes = [Showtime]() {
    didSet { refresh() }
  }
  weak var delegate: ShowtimeCellDelegate?
  private(set) lazy var popTip: AMPopTip = {
    return AMPopTip().then {
      $0.shouldDismissOnTap = false
      $0.shouldDismissOnTapOutside = false
      $0.edgeMargin = 5
      $0.offset = 2
      $0.padding = 0
    }
  }()
  var containerView: UIScrollView!
  var color: UIColor = .accentColor() {
    didSet {
      leftColor = color + UIColor.whiteColor().alpha(0.6)
      rightColor = showtimes.count > 5 ? color : color + UIColor.whiteColor().alpha(0.2)
      collectionView.reloadData()
    }
  }
  private(set) lazy var collectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout().then {
      $0.scrollDirection = self.scrollDirection
      $0.minimumInteritemSpacing = 5
      $0.minimumLineSpacing = 5
      $0.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    return UICollectionView(frame: .zero, collectionViewLayout: flowLayout).then {
      $0.optimize()
      $0.autoresizingMask = .FlexibleWidth
      $0.backgroundColor = .clearColor()
      $0.showsHorizontalScrollIndicator = false
      $0.showsVerticalScrollIndicator = false
      $0.scrollsToTop = false
      $0.dataSource = self
      $0.delegate = self
      $0.registerReusableCell(ShowtimeListItemCell)
    }
  }()

  // MARK: Private properties

  private var scrollDirection = UICollectionViewScrollDirection.Horizontal
  private var highlightedCell: ShowtimeListItemCell?
  private lazy var leftColor: UIColor = {
    return self.color + UIColor.whiteColor().alpha(0.6)
  }()
  private lazy var rightColor: UIColor = {
    return self.showtimes.count > 5 ? self.color : self.color + UIColor.whiteColor().alpha(0.2)
  }()

  // MARK: Initialization

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    optimize()
    backgroundColor = .clearColor()
    selectionStyle = .Gray
    selectedBackgroundView = UIView(frame: bounds).then {
      $0.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
      $0.backgroundColor = UIColor.blackColor().alpha(0.5)
    }
    contentView.addSubview(collectionView)

    tap { gestureRecognizer in
      let location = gestureRecognizer.locationInView(self.collectionView)
      if self.delegate?.visiblePopTip != nil && self.collectionView.indexPathForItemAtPoint(location) == nil {
        gestureRecognizer.cancelsTouchesInView = true
        self.delegate?.visiblePopTip?.hide()
      } else {
        gestureRecognizer.cancelsTouchesInView = false
      }
    }
    longPress { gestureRecognizer in
      let state = gestureRecognizer.state
      if self.highlightedCell != nil && (state == .Cancelled || state == .Failed || state == .Ended) {
        self.highlightedCell?.reversed = false
        self.highlightedCell = nil
      }

      let location = gestureRecognizer.locationInView(self.collectionView)
      if let indexPath = self.collectionView.indexPathForItemAtPoint(location) {
        if state == .Began {
          let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ShowtimeListItemCell
          cell?.reversed = true
          self.highlightedCell = cell
        } else if state == .Ended {
          self.delegate?.openShowtime(self.showtimes[indexPath.row])
        }
      }
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UITableViewCell

  override func prepareForReuse() {
    collectionView.contentOffset = .zero
    highlightedCell = nil
  }

  // MARK: Public methods

  func itemCellSize(showtime: Showtime) -> CGSize {
    return CGSize(width: showtime.summaryString(cinemaForShowtime(showtime)).size(.zero).width + 30,
      height: collectionView.height - 20)
  }

  func refresh() {}
  func cinemaForShowtime(showtime: Showtime) -> Cinema? { return nil }

  // MARK: Private methods

  private func drawPopTipForCell(indexPath: NSIndexPath) {
    let showtime = showtimes[indexPath.row]
    guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ShowtimeListItemCell,
      movie = movie else { return }

    let cellFrame = collectionView.convertRect(cell.frame, toView: containerView)
    let shouldPointUp = containerView.contentSize.height - cellFrame.maxY < 200 &&
      containerView.contentSize.height >= containerView.height - 200

    cell.reversed = true
    popTip.popoverColor = cell.color.alpha(1)
    popTip.dismissHandler = {
      cell.reversed = false
      self.delegate?.visiblePopTip = nil
    }
    popTip.tapHandler = { self.delegate?.openShowtime(showtime) }
    popTip.showCustomView(PopTipView(showtime: showtime, movie: movie, buttonClosure: delegate?.buyTicketForShowtime),
      direction: shouldPointUp ? .Up : .Down, inView: containerView, fromFrame: cellFrame)
    delegate?.visiblePopTip = popTip
  }
}

// MARK: - UICollectionViewDataSource

extension ShowtimeListCell: UICollectionViewDataSource {
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return showtimes.count
  }

  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
      return itemCellSize(showtimes[indexPath.row])
  }

  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
    -> UICollectionViewCell {
      return collectionView.dequeueReusableCell(indexPath: indexPath, cellType: ShowtimeListItemCell.self).then {
        let showtime = showtimes[indexPath.row]
        let ratio = CGFloat(indexPath.row) / CGFloat(showtimes.count)
        $0.configure(showtime, cinema: cinemaForShowtime(showtime))
        $0.color = leftColor.alpha(1.0 - ratio) + rightColor.alpha(ratio)
      }
  }
}

// MARK: - UICollectionViewDelegate

extension ShowtimeListCell: UICollectionViewDelegate {
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    if let visiblePopTip = delegate?.visiblePopTip {
      if visiblePopTip.isAnimating { return }

      let cell = collectionView.cellForItemAtIndexPath(indexPath)!
      if collectionView.convertRect(cell.frame, toView: containerView) == visiblePopTip.fromFrame {
        return visiblePopTip.hide()
      }

      let oldDismissHandler = visiblePopTip.dismissHandler
      visiblePopTip.dismissHandler = {
        oldDismissHandler()
        self.drawPopTipForCell(indexPath)
      }
      visiblePopTip.hide()
    } else {
      drawPopTipForCell(indexPath)
    }
  }
}
