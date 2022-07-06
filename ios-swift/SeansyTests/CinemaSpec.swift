import Quick
import Nimble
import Unbox

class CinemaSpec: QuickSpec {
  override func spec() {
    var cinema: Cinema!
    beforeEach {
      guard let dict = JSONFromFile("cinema") as? UnboxableDictionary else {
        return fail()
      }
      cinema = Unbox(dict)
    }
    
    describe("Cinema model") {
      it("parses all properties") {
        expect(cinema.id).to(equal("56c417a363f1caeb4434526c"))
        expect(cinema.name).to(equal("Cinemax (Dostyk Plaza) Dolby Atmos 3D"))
        expect(cinema.city).to(equal("Алматы"))
        expect(cinema.address).to(equal("Самал-2, пр.Достык 111, уг.ул. Жолдасбекова, ТРЦ Dostyk Plaza"))
        expect(cinema.location?.latitude).to(equal(43.2331632))
        expect(cinema.location?.longitude).to(equal(76.9565775))
        expect(cinema.phone).to(equal("+7 (727) 222-0077"))
        expect(cinema.photoUrl).to(equal("http://kino.kz/images/cinemas/119.jpg"))
      }
    }
  }
}