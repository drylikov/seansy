import Foundation
import Unbox

final class MovieCrewMember: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let name = "name"
    static let photoUrl = "photoUrl"
  }

  // MARK: Inputs

  let name: String
  let photoUrl: NSURL?

  // MARK: Public properties

  var nameInitials: String {
    return name.componentsSeparatedByCharactersInSet(.whitespaceCharacterSet()).reduce("") { initials, word in
      return word.length > 0 ? initials + "\(word[0])".uppercaseString : initials
    }
  }

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    name = unboxer.unbox(Key.name)
    photoUrl = unboxer.unbox(Key.photoUrl)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    name = aDecoder.decodeObjectForKey(Key.name) as! String
    photoUrl = aDecoder.decodeObjectForKey(Key.photoUrl) as? NSURL
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(name, forKey: Key.name)
    aCoder.encodeObject(photoUrl, forKey: Key.photoUrl)
  }
}

// MARK: -

final class MovieCrew: NSObject, NSCoding, Unboxable {

  // MARK: Private types

  private enum Key {
    static let cast = "cast"
    static let directors = "directors"
    static let producers = "producers"
    static let writers = "writers"
    static let composers = "composers"
  }

  // MARK:Inputs

  let cast: [MovieCrewMember]?
  let directors: [MovieCrewMember]?
  let producers: [MovieCrewMember]?
  let writers: [MovieCrewMember]?
  let composers: [MovieCrewMember]?

  // MARK: Unboxable

  init(unboxer: Unboxer) {
    cast = unboxer.unbox(Key.cast)
    directors = unboxer.unbox(Key.directors)
    producers = unboxer.unbox(Key.producers)
    writers = unboxer.unbox(Key.writers)
    composers = unboxer.unbox(Key.composers)
  }

  // MARK: NSCoding

  init?(coder aDecoder: NSCoder) {
    cast = aDecoder.decodeObjectForKey(Key.cast) as? [MovieCrewMember]
    directors = aDecoder.decodeObjectForKey(Key.directors) as? [MovieCrewMember]
    producers = aDecoder.decodeObjectForKey(Key.producers) as? [MovieCrewMember]
    writers = aDecoder.decodeObjectForKey(Key.writers) as? [MovieCrewMember]
    composers = aDecoder.decodeObjectForKey(Key.composers) as? [MovieCrewMember]
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(cast, forKey: Key.cast)
    aCoder.encodeObject(directors, forKey: Key.directors)
    aCoder.encodeObject(producers, forKey: Key.producers)
    aCoder.encodeObject(writers, forKey: Key.writers)
    aCoder.encodeObject(composers, forKey: Key.composers)
  }
}
