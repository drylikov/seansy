import Sugar
import UIKit
import XLPagerTabStrip

final class MovieListChildViewController: TabBarItemPagerChildViewController {

  // MARK: Inputs

  let type: MovieType

  // MARK: TabBarItemPagerChildViewController

  override var scrollView: UIScrollView { return listView }

  // MARK: Public properties

  private(set) lazy var listView: MovieListView = {
    return MovieListView(type: self.type).then {
      $0.alwaysBounceVertical = true
      $0.addSubview(self.refreshControl)
      $0.sendSubviewToBack(self.refreshControl)
    }
  }()
  let refreshControl = UIRefreshControl().then { $0.tintColor = .whiteColor() }

  // MARK: Initialization

  init(type: MovieType) {
    self.type = type
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - IndicatorInfoProvider

extension MovieListChildViewController: IndicatorInfoProvider {
  func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
    return IndicatorInfo(title: type.rawValue)
  }
}
