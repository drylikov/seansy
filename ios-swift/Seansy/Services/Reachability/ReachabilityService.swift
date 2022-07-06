//
//  Copyright (c) 2015 Krunoslav Zaher.
//

import ReachabilitySwift
import RxCocoa
import RxSwift

enum ReachabilityStatus {
  case Reachable, Unreachable
}

final class ReachabilityService {

  // MARK: Public properties

  var reachabilityChanged: Observable<ReachabilityStatus> { return reachabilityStatus.asObservable() }

  // Private properties

  private let reachabilityRef = try! Reachability.reachabilityForInternetConnection()
  private let reachabilityStatus = Variable(ReachabilityStatus.Reachable)

  // MARK: Initialization

  static let sharedReachabilityService = ReachabilityService()

  init() {
    reachabilityRef.whenReachable = { reachability in
      self.reachabilityStatus.value = .Reachable
    }

    reachabilityRef.whenUnreachable = { reachability in
      self.reachabilityStatus.value = .Unreachable
    }

    try! reachabilityRef.startNotifier()
  }
}

extension ObservableConvertibleType {
  func retryOnBecomesReachable(valueOnFailure: E, reachabilityService: ReachabilityService) -> Observable<E> {
    return self.asObservable()
      .catchError { error -> Observable<E> in
        reachabilityService.reachabilityChanged
          .filter { $0 == .Reachable }
          .flatMap { _ in Observable.error(error) }
          .startWith(valueOnFailure)
      }
      .retry()
  }
}
