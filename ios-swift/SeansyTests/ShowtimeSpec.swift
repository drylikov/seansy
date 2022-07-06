import Quick
import Nimble
import Unbox

class ShowtimeSpec: QuickSpec {
  override func spec() {
    var showtime: Showtime!
    beforeEach {
      guard let dict = JSONFromFile("showtime") as? UnboxableDictionary else {
        return fail()
      }
      showtime = Unbox(dict)
    }
    
    describe("Showtime model") {
      it("parses all properties") {
        expect(showtime.id).to(equal("56c944af7828ffc6269ab1d7"))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        expect(dateFormatter.stringFromDate(showtime.time)).to(equal("2016-02-21T07:10:00.000Z"))
        expect(showtime.format).to(equal("Dolby Atmos"))
        expect(showtime.language).to(equal("англ. яз"))
        expect(showtime.prices?.adult).to(equal(1200))
        expect(showtime.prices?.children).to(beNil())
        expect(showtime.prices?.student).to(equal(1000))
        expect(showtime.prices?.vip).to(beNil())
        expect(showtime.movieId).to(equal("56b8219e948795977a4023d2"))
        expect(showtime.cinemaId).to(equal("56c417a363f1caeb4434526c"))
        expect(showtime.ticketonId).to(equal("636085"))
      }
    }
  }
}