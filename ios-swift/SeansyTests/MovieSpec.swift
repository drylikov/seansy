import Quick
import Nimble
import Unbox

class MovieSpec: QuickSpec {
  override func spec() {
    var movie: Movie!
    beforeEach {
      guard let dict = JSONFromFile("movie") as? UnboxableDictionary else {
        return fail()
      }
      movie = Unbox(dict)
    }
    
    describe("Movie model") {
      it("parses all properties") {
        expect(movie.id).to(equal("56b8219e948795977a4023d2"))
        expect(movie.title).to(equal("Дэдпул"))
        expect(movie.originalTitle).to(equal("Deadpool"))
        expect(movie.synopsis).to(contain("Уэйд Уилсон — наёмник"))
        expect(movie.ratings?[.Kinopoisk]).to(beTruthy())
        expect(movie.ratings?[.IMDB]).to(beTruthy())
        expect(movie.ratings?[.RTCritics]).to(beTruthy())
        expect(movie.ratings?[.RTAudience]).to(beTruthy())
        expect(movie.ratings?[.Metacritic]).to(beTruthy())
        expect(movie.popularity).to(equal(1))
        expect(movie.posterUrl?.absoluteString).to(beginWith("http://avatars.mds.yandex.net"))
        expect(movie.backdropUrl?.absoluteString).to(beginWith("http://avatars.mds.yandex.net"))
        expect(movie.trailers).to(haveCount(1))
        expect(movie.genres).to(contain("комедия", "приключения", "боевик", "фантастика"))
        expect(movie.stills).to(haveCount(10))
        expect(movie.directors).to(haveCount(1))
        expect(movie.screenwriters).to(haveCount(2))
        expect(movie.cast).to(haveCount(10))
        expect(movie.year).to(equal(2016))
        expect(movie.countries).to(haveCount(2))
        expect(movie.runtime).to(equal(108))
        expect(movie.ageRating).to(equal(18))
        expect(movie.bonusScene?.afterCredits).to(beTrue())
        expect(movie.bonusScene?.duringCredits).to(beTrue())
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        expect(movie.releaseDate.flatMap { dateFormatter.stringFromDate($0) }).to(equal("2016-02-11T00:00:00.000Z"))
      }
      
      it("stringifies properties") {
        expect(movie.shortReleaseDateString).to(equal("11 февраля"))
        expect(movie.longReleaseDateString).to(beginWith("11 февраля - "))
        expect(movie.genresString).to(equal("комедия, приключения, боевик, фантастика"))
        expect(movie.directorsString).to(equal("Тим Миллер"))
        expect(movie.screenwritersString).to(equal("Ретт Риз, Пол Верник"))
        expect(movie.bonusSceneString).to(equal("Бонусные сцены до и после титров"))
        expect(movie.ratings?[.Kinopoisk]?.attributedString.string).to(equal("8.0/10"))
        expect(movie.ratings?[.IMDB]?.attributedString.string).to(equal("8.6/10"))
        expect(movie.ratings?[.RTCritics]?.attributedString.string).to(equal("83%"))
        expect(movie.ratings?[.RTAudience]?.attributedString.string).to(equal("94%"))
        expect(movie.ratings?[.Metacritic]?.attributedString.string).to(equal("65%"))
      }
    }
  }
}
