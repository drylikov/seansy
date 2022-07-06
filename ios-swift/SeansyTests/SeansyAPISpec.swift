import Quick
import Nimble
import RxSwift
import Dip

class SeansyAPISpec: QuickSpec {
  let dip = DependencyContainer() { dip in
    dip.register(.Singleton) {
      SeansyAPIProvider(payload: ["id": 1, "client": "test"], secret: Secrets.seansyApiSecret)
    }
  }
  
  override func spec() {
    let disposeBag = DisposeBag()
    let seansyApiProvider: SeansyAPIProvider = try! dip.resolve()
    
    describe("GET /movies") {
      it("returns an array of movie objects") {
        waitUntil(timeout: 2) { done in
          seansyApiProvider
            .request(.Movies)
            .mapArray(Movie.self, rootKey: "data")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { movies in
              expect(movies).toNot(beEmpty())
              done()
            }, onError: { error in
              fail("Failed to get movies: \(error)")
            }).addDisposableTo(disposeBag)
        }
      }
    }

    describe("GET /cinemas") {
      it("returns an array of cinema objects") {
        waitUntil(timeout: 2) { done in
          seansyApiProvider
            .request(.Cinemas)
            .mapArray(Cinema.self, rootKey: "data")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { cinemas in
              expect(cinemas).toNot(beEmpty())
              done()
            }, onError: { error in
              fail("Failed to get cinemas: \(error)")
            }).addDisposableTo(disposeBag)
        }
      }
    }
    
    describe("GET /showtimes") {
      it("returns an array of showtime objects") {
        waitUntil(timeout: 2) { done in
          seansyApiProvider
            .request(.Showtimes("Алматы"))
            .mapArray(Showtime.self, rootKey: "data")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { showtimes in
              expect(showtimes).toNot(beEmpty())
              done()
            }, onError: { error in
              fail("Failed to get showtimes: \(error)")
            }).addDisposableTo(disposeBag)
        }
      }
    }
  }
}
