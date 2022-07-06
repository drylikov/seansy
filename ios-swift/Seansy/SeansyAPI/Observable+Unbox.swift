import Moya
import RxSwift
import Unbox

extension ObservableType where E == Response {
  func mapObject<T: Unboxable>(type: T.Type, rootKey: String? = nil) -> Observable<T> {
    return observeOn(SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
      .flatMap { Observable.just(try $0.mapObject(rootKey)) }
      .observeOn(MainScheduler.instance)
  }

  func mapArray<T: Unboxable>(type: T.Type, rootKey: String? = nil) -> Observable<[T]> {
    return observeOn(SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
      .flatMap { Observable.just(try $0.mapArray(rootKey)) }
      .observeOn(MainScheduler.instance)
  }
}
