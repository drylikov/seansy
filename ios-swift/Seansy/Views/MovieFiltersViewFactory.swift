import Reusable
import Sugar
import Tactile
import UIKit

private class FilterViewLabel: UILabel {
  override init(frame: CGRect) {
    super.init(frame: frame)

    optimize()
    textColor = .whiteColor()
    font = .regularFontOfSize(16)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

private final class BorderedLabel: FilterViewLabel {
  override init(frame: CGRect) {
    super.init(frame: frame)

    optimize()
    textAlignment = .Center
    layer.borderWidth = 1
    layer.borderColor = UIColor.accentColor().CGColor
    layer.cornerRadius = 5
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

private final class GenresSelectorCell: UICollectionViewCell, Reusable {

  // MARK: Public properties

  var active = false {
    didSet {
      textLabel.layer.backgroundColor = (active ? UIColor.accentColor() : UIColor.clearColor()).CGColor
      textLabel.textColor = active ? .primaryColor() : .whiteColor()
    }
  }

  // MARK: Private properties

  private lazy var textLabel: BorderedLabel = {
    return BorderedLabel(frame: self.bounds).then {
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(16)
      $0.textAlignment = .Center
      $0.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    }
  }()

  // MARK: Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(textLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UICollectionViewCell

  override func prepareForReuse() {
    textLabel.text = nil
    active = false
  }

  // MARK: Public methods

  func configure(text: String) {
    textLabel.text = text
  }
}

// MARK -

final class MovieFiltersViewFactory: NSObject {

  // MARK: Private types

  private struct Values {
    let min: Float
    let max: Float
    let current: Float
  }

  // MARK: Inputs

  let filters: MovieFilters

  // MARK: Public properties

  lazy var ratingSlider: UIView = {
    return MovieFiltersViewFactory.slider(
      title: "Мин. рейтинг:",
      values: Values(
        min: self.filters.minRating,
        max: self.filters.maxRating,
        current: self.filters.ratingFilter
      ),
      format: "%.1f%%") { self.filters.ratingFilter = $0 }
  }()

  lazy var runtimeSlider: UIView = {
    return MovieFiltersViewFactory.slider(
      title: "Макс. длительность:",
      values: Values(
        min: Float(self.filters.minRuntime),
        max: Float(self.filters.maxRuntime),
        current: Float(self.filters.runtimeFilter)
      ),
      format: "%.0f мин.") { self.filters.runtimeFilter = Int($0) }
  }()

  lazy var childrenSwitch: UIView = {
    return UIView(frame: CGRect(width: screenWidth, height: 0)).then {
      $0.optimize()

      let titleLabel = FilterViewLabel(frame: CGRect(x: 10, y: 0, width: 0, height: 0)).then {
        $0.text = "Для детей:"
        $0.sizeToFit()
      }
      $0.addSubview(titleLabel)

      let switchControl = UISwitch().then {
        $0.optimize()
        $0.top = 10
        $0.left = titleLabel.right + 10
        $0.on = self.filters.childrenFilter
        $0.addTarget(self, action: #selector(MovieFiltersViewFactory.updateChildrenSwitch(_:)),
          forControlEvents: .ValueChanged)
        titleLabel.centerY = $0.centerY
      }
      $0.addSubview(switchControl)
      $0.height = switchControl.bottom + 10
    }
  }()

  lazy var genresSelector: UIView = {
    return UIView(frame: CGRect(width: screenWidth, height: 0)).then {
      $0.optimize()

      let titleLabel = FilterViewLabel(frame: CGRect(x: 10, y: 10, width: 0, height: 0)).then {
        $0.text = "Жанры:"
        $0.sizeToFit()
      }
      $0.addSubview(titleLabel)

      let flowLayout = UICollectionViewFlowLayout().then {
        $0.scrollDirection = .Horizontal
        $0.minimumInteritemSpacing = 2
        $0.minimumLineSpacing = 2
        $0.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
      }
      let collectionView = UICollectionView(frame: CGRect(x: 0, y: titleLabel.bottom + 10, width: $0.width, height: 34),
        collectionViewLayout: flowLayout).then {
          $0.optimize()
          $0.backgroundColor = .clearColor()
          $0.showsHorizontalScrollIndicator = false
          $0.dataSource = self
          $0.delegate = self
          $0.registerReusableCell(GenresSelectorCell)
      }
      $0.addSubview(collectionView)
      $0.height = collectionView.bottom + 10
    }
  }()

  // MARK: Initialization

  init(filters: MovieFilters) {
    self.filters = filters
  }

  // MARK: Public methods

  func updateChildrenSwitch(sender: UISwitch) {
    filters.childrenFilter = sender.on
  }

  // MARK: Private methods

  private static func slider(title title: String, values: Values, format: String, handler: Float -> Void) -> UIView {
    return UIView(frame: CGRect(width: screenWidth, height: 0)).then { view in
      let titleLabel = FilterViewLabel(frame: CGRect(x: 10, y: 10, width: 0, height: 0)).then {
        $0.text = title
        $0.sizeToFit()
      }
      let valueLabel = BorderedLabel(frame: CGRect(x: titleLabel.right + 10, y: 10, width: 0, height: 0)).then {
        $0.text = String(format: format, values.current)
        $0.sizeToFit()
        $0.width += 10
      }
      let minValueLabel = FilterViewLabel(frame: CGRect(x: 10, y: titleLabel.bottom, width: 0, height: 0)).then {
        $0.text = String(format: values.min % 1 == 0 ? "%.0f" : "%.1f", values.min)
        $0.sizeToFit()
        $0.height = 45
      }
      let maxValueLabel = FilterViewLabel(frame: CGRect(x: 0, y: titleLabel.bottom, width: 0, height: 0)).then {
        $0.text = String(format: values.max % 1 == 0 ? "%.0f" : "%.1f", values.max)
        $0.sizeToFit()
        $0.height = 45
        $0.left = view.width - $0.width - 10
      }
      let slider = UISlider(frame: CGRect(x: minValueLabel.right + 10, y: titleLabel.bottom,
        width: maxValueLabel.left - minValueLabel.right - 20, height: 45)).then {
          $0.optimize()
          $0.continuous = false
          $0.minimumValue = values.min
          $0.maximumValue = values.max
          $0.value = values.current
          $0.on(.ValueChanged) { slider in
            handler(slider.value)

            valueLabel.text = String(format: format, slider.value)
            valueLabel.sizeToFit()
            valueLabel.width += 10
          }
      }
      view.height = slider.bottom + 10

      [titleLabel, valueLabel, minValueLabel, maxValueLabel, slider].forEach { view.addSubview($0) }
    }
  }
}

// MARK: - UICollectionViewDataSource

extension MovieFiltersViewFactory: UICollectionViewDataSource {
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 1 }

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return filters.genres.count
  }

  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
      let width = min(collectionView.width - 20, filters.genres[indexPath.row].size(.regularFontOfSize(16)).width)
      return CGSize(width: 14 + width, height: collectionView.height)
  }

  func collectionView(collectionView: UICollectionView,
    cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      return collectionView.dequeueReusableCell(indexPath: indexPath, cellType: GenresSelectorCell.self).then {
        let genre = filters.genres[indexPath.row]
        $0.active = filters.genresFilter.contains(genre)
        $0.configure(genre)
      }
  }
}

// MARK: - UICollectionViewDelegate

extension MovieFiltersViewFactory: UICollectionViewDelegate {
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! GenresSelectorCell
    let genre = filters.genres[indexPath.row]

    if let index = filters.genresFilter.indexOf(genre) {
      filters.genresFilter.removeAtIndex(index)
      cell.active = false
    } else {
      filters.genresFilter.append(genre)
      cell.active = true
    }
  }
}
