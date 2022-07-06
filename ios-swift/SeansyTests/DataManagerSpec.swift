import Quick
import Nimble
import RxSwift
import Dip

class DataManagerSpec: QuickSpec {
  let dip = DependencyContainer() { dip in
    dip.register(.Singleton) {
      SeansyAPIProvider(payload: ["id": 1, "client": "test"], secret: Secrets.seansyApiSecret)
    }
    dip.register(.Singleton) { DataManager(seansyApiProvider: try dip.resolve()) }
  }
}