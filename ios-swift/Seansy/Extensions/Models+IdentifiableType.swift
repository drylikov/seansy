import RxDataSources

extension Movie: IdentifiableType {
  typealias Identity = String
  var identity: String { return id }
}

extension Cinema: IdentifiableType {
  typealias Identity = String
  var identity: String { return id }
}

extension SearchItem: IdentifiableType {
  typealias Identity = String
  var identity: String { return query }
}
