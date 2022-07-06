import Cheetah
import NSObject_Rx
import RxSwift
import Sugar
import Tactile
import Transporter
import UIKit

// MARK: Labeled Protocol

protocol Labeled {
  var descriptionLabel: MovieInfoLabel { get }
}

// MARK: -

enum InfoViewState {
  case Detailed, Summary
}

final class MovieInfoView: UIScrollView {

  // MARK: Inputs

  let movie: Movie
  let presenter: MovieDetailsPresenter

  // MARK: Public properties

  private(set) var summaryHeight: CGFloat = 0.0
  private(set) var detailedHeight: CGFloat = 0.0

  // Views
  lazy var posterImageView: MoviePosterView = {
    return MoviePosterView(
      frame: CGRect(x: 10, y: 0, width: 70, height: 100),
      posterUrl: self.movie.posterUrl,
      presenter: self.presenter
    )
  }()
  private(set) lazy var titleLabel: MovieInfoLabel = {
    return MovieInfoLabel(frame: CGRect(x: self.posterImageView.right + 10, y: 0,
      width: self.width - self.posterImageView.right - 20, height: 0)).then {
        $0.optimize()
        $0.textColor = .whiteColor()
        $0.font = .lightFontOfSize(44)
        $0.text = self.movie.title
        $0.adjustFontSize(self.movie.title.length > 15 ? 2 : 1, minSize: 20)
    }
  }()

  // MARK: Private properties

  private lazy var stateMachine: StateMachine<InfoViewState> = {
    let summaryState = State(InfoViewState.Summary)
    summaryState.didEnterState = { _ in self.updateState(.Summary) }
    let detailedState = State(InfoViewState.Detailed)
    detailedState.didEnterState = { _ in self.updateState(.Detailed) }

    return StateMachine(initialState: summaryState, states: [detailedState])
  }()

  // Views
  private lazy var trailerButton: SpringyButton? = {
    guard let trailers = self.movie.trailers else { return nil }

    return SpringyButton(frame: self.bounds).then {
      $0.optimize()
      $0.tintColor = .whiteColor()
      $0.setImage(UIImage(.PlayIcon).icon, forState: .Normal)

      let playTrailer: UIButton -> Void = { button in
        guard let trailers = self.movie.trailers else { return }

        button.cheetah.remove()
          .scale(1.2).duration(0.2).easeInCubic
          .wait()
          .scale(1.0).duration(0.2).easeOutCubic
          .run().forever
        self.presenter.playTrailer(trailers[0].youtubeId)
          .subscribeNext { _ in
            button.cheetah.remove().scale(1.0).run()
          }
          .addDisposableTo(self.rx_disposeBag)
      }
      $0.on(.TouchUpInside, playTrailer)
    }
  }()
  private lazy var originalTitleLabel: MovieInfoLabel? = {
    if self.movie.originalTitle == nil && self.movie.year == nil { return nil }

    return MovieInfoLabel(frame: yLens.to(self.titleLabel.bottom + 10, self.titleLabel.frame)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor

      if let originalTitle = self.movie.originalTitle {
        var text = "\(originalTitle)"
        if let year = self.movie.year {
          text += " (\(year))"
        }
        $0.text = text
        $0.font = .regularFontOfSize(14)
      } else if let year = self.movie.year {
        $0.text = "\(year)"
        $0.font = .regularFontOfSize(16)
      }
      $0.sizeToFitInHeight(0)
    }
  }()
  private lazy var releaseDateLabel: MovieInfoLabel? = {
    guard let releaseDateString = self.movie.longReleaseDateString else { return nil }

    return MovieInfoLabel(frame: xLens.to(10, .zero)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.textAlignment = .Center
      $0.font = .regularFontOfSize(16)
      $0.layer.borderWidth = 1
      $0.layer.borderColor = UIColor.whiteColor().CGColor
      $0.layer.cornerRadius = 5
      $0.text = releaseDateString
      $0.sizeToFit()
      $0.width += 10
      $0.height += 10
    }
  }()
  private lazy var ratingsView: MovieRatingsView? = {
    guard let ratings = self.movie.ratings else { return nil }
    if ratings.empty { return nil }

    return MovieRatingsView(frame: CGRect(width: self.width, height: 20), ratings: ratings)
  }()
  private lazy var genresLabel: MovieInfoLabel? = {
    guard let genresString = self.movie.genresString else { return nil }

    return MovieInfoLabel(frame: CGRect(x: 10, y: 0, width: self.width - 20, height: 0)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .regularFontOfSize(16)
      $0.text = genresString
      $0.sizeToFitInHeight(60)
    }
  }()
  private lazy var ageRatingLabel: MovieInfoLabel? = {
    guard let ageRating = self.movie.ageRating else { return nil }

    return MovieInfoLabel(frame: xLens.to(10, .zero)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.textAlignment = .Center
      $0.font = .regularFontOfSize(16)
      $0.layer.borderWidth = 1
      $0.layer.borderColor = BackdropColors.defaultTextColor.CGColor
      $0.layer.shadowOffset = CGSize(width: 1, height: 1)
      $0.layer.shadowRadius = 0
      $0.layer.shadowColor = UIColor.blackColor().CGColor
      $0.layer.shadowOpacity = 0.5
      $0.text = "\(ageRating)+"
      $0.sizeToFit()
      $0.width += 8
      $0.height += 4
    }
  }()
  private lazy var runtimeLabel: MovieInfoLabel? = {
    guard let runtimeString = self.movie.runtimeString else { return nil }

    return MovieInfoLabel(frame: xLens.to(10, .zero)).then {
      $0.optimize()
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .regularFontOfSize(16)
      $0.text = runtimeString
      $0.sizeToFit()
      if let ageRatingLabel = self.ageRatingLabel {
        $0.left = ageRatingLabel.right + 10
        $0.centerY = ageRatingLabel.centerY
      }
    }
  }()
  private lazy var synopsisLabel: MovieInfoLabel? = {
    guard let synopsis = self.movie.synopsis else { return nil }

    return MovieInfoLabel(frame: CGRect(x: 10, y: 0, width: self.width - 20, height: 0)).then {
      $0.textColor = .whiteColor()
      $0.font = .regularFontOfSize(14)
      $0.contentMode = .TopLeft
      $0.text = synopsis
      $0.sizeToFitInHeight(100)
    }
  }()
  private lazy var stillsView: MovieStillsView? = {
    guard let stills = self.movie.stills?.map({ Still(url: $0) }) else { return nil }

    let viewModel = MovieInfoCarouselModel<Still>(data: stills, description: "Кадры")
    return MovieStillsView(frame: widthLens.to(self.width, .zero), viewModel: viewModel, presenter: self.presenter)
  }()
  private lazy var reviewsView: MovieReviewsView? = {
    guard let reviews = self.movie.pressReviews else { return nil }

    let viewModel = MovieInfoCarouselModel<MoviePressReview>(data: reviews, description: "Рецензии", itemWidth: 250)
    return MovieReviewsView(frame: widthLens.to(self.width, .zero), viewModel: viewModel, presenter: self.presenter)
  }()
  private lazy var directorsLabel: MovieInfoList? = {
    guard let directors = self.movie.crew?.directors, directorsString = self.movie.directorsString else { return nil }

    let description = directors.count > 1 ? "Режиссеры:" : "Режиссер:"
    return MovieInfoList(
      frame: CGRect(x: 10, y: 0, width: self.width - 20, height: 0),
      description: description,
      text: directorsString
    )
  }()
  private lazy var writersLabel: MovieInfoList? = {
    guard let writers = self.movie.crew?.writers, writersString = self.movie.writersString else { return nil }

    return MovieInfoList(
      frame: CGRect(x: 10, y: 0, width: self.width - 20, height: 0),
      description: "Сценарий:",
      text: writersString
    )
  }()
  private lazy var castView: MovieCastView? = {
    guard let cast = self.movie.crew?.cast else { return nil }

    let itemWidth = self.width / (self.width < 414  ? 3 : 5) - 10
    let itemHeight = itemWidth / 0.63 + 50

    let viewModel = MovieInfoCarouselModel<MovieCrewMember>(
      data: cast,
      description: "Актеры",
      itemHeight: itemHeight,
      itemWidth: itemWidth
    )
    return MovieCastView(frame: widthLens.to(self.width, .zero), viewModel: viewModel, presenter: self.presenter)
  }()
  private lazy var bonusSceneLabel: MovieInfoLabel? = {
    guard let bonusSceneString = self.movie.bonusSceneString else { return nil }

    return MovieInfoLabel(frame: CGRect(x: 10, y: 0, width: self.width - 20, height: 0)).then {
      $0.textColor = BackdropColors.defaultTextColor
      $0.font = .regularFontOfSize(16)
      $0.text = "⚫︎ " + bonusSceneString
      $0.sizeToFitInHeight(0)
    }
  }()

  // MARK: Initialization

  init(frame: CGRect, movie: Movie, presenter: MovieDetailsPresenter) {
    self.movie = movie
    self.presenter = presenter
    super.init(frame: frame)

    optimize()
    showsVerticalScrollIndicator = false

    setUpSummaryViews()
    setUpDetailedViews()

    contentInset.top = height - summaryHeight
    contentSize.height = detailedHeight

    if let trailerButton = trailerButton {
      trailerButton.height = contentInset.top
      addSubview(trailerButton)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public methods

  func activateState(state: InfoViewState) {
    stateMachine.activateState(state)
  }

  func updateTextColors(color: UIColor) {
    ([originalTitleLabel, genresLabel, ageRatingLabel, runtimeLabel, stillsView, reviewsView, directorsLabel,
      writersLabel, castView, bonusSceneLabel] as [UIView?]).flatMap { $0 }.forEach { view in
        if let label = view as? UILabel {
          label.textColor = color
          if label == ageRatingLabel { label.layer.borderColor = color.CGColor }
        } else if let labeled = view as? Labeled {
          labeled.descriptionLabel.textColor = color
        }
    }
  }

  func hideTrailerButton() {
    trailerButton?.hidden = true
  }

  func unhideTrailerButton() {
    guard let trailerButton = trailerButton else { return }

    if trailerButton.hidden {
      trailerButton.layer.transform = CATransform3DMakeScale(0, 0, 1)
      trailerButton.hidden = false
      trailerButton.cheetah.scale(1.0).spring(tension: 40, friction: 7).duration(0.3).run()
    }
  }

  // MARK: Private methods

  private func setUpSummaryViews() {
    addSubview(posterImageView)
    addSubview(titleLabel)

    summaryHeight = ([
      originalTitleLabel, releaseDateLabel, ratingsView, genresLabel, ageRatingLabel, runtimeLabel
      ] as [UIView?]).flatMap { $0 }.reduce(0) { offset, view in
        if view == originalTitleLabel {
          let height = view.bottom - titleLabel.top
          let centerOffset = (posterImageView.height - height) / 2 - 5
          titleLabel.top += centerOffset
          view.top += centerOffset
        } else if view == runtimeLabel {
          view.top = ageRatingLabel == nil ? offset : ageRatingLabel!.top
        } else {
          view.top = offset
        }
        addSubview(view)

        if view == originalTitleLabel {
          return (posterImageView.bottom > view.bottom ? posterImageView.bottom : view.bottom) + 10
        } else {
          return view.bottom + 10
        }
    }
  }

  private func setUpDetailedViews() {
    detailedHeight = ([
      synopsisLabel, stillsView, reviewsView, directorsLabel, writersLabel, castView, bonusSceneLabel
      ] as [UIView?]).flatMap { $0 }.reduce(summaryHeight) { offset, view in
        view.top = offset
        addSubview(view)

        if view == synopsisLabel {
          summaryHeight = view.bottom + 10
          return offset + synopsisLabel!.sizeThatFitsInHeight(0).height + 10
        } else {
          return view.bottom + 10
        }
    }
  }

  private func updateState(state: InfoViewState) {
    let alpha: CGFloat = state == .Detailed ? 1 : 0
    UIView.animateWithDuration(0.3) { ([
      self.stillsView, self.reviewsView, self.directorsLabel, self.writersLabel, self.castView
      ] as [UIView?]).flatMap { $0 }.forEach {
        $0.alpha = alpha
      }
      if let synopsisLabel = self.synopsisLabel {
        synopsisLabel.height = synopsisLabel.sizeThatFitsInHeight(state == .Detailed ? 0 : 100).height
      }
    }
  }
}
