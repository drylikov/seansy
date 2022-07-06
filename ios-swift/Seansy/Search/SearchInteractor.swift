protocol SearchInteractor: MovieDetailsRouteInteractor {
  var recentSearches: [SearchItem] { get }
  var queryExamples: [SearchItem] { get }
  func addRecentSearch(item: SearchItem)
  func clearRecentSearches()
  func suggestionsForQuery(query: String) -> [SearchItem]
  func resultsFromSuggestion(suggestion: SearchItem) -> SearchResults?
}

extension DataManager: SearchInteractor {
  var queryExamples: [SearchItem] { return searchEngine.examples }

  func addRecentSearch(item: SearchItem) {
    //    recentSearches.append(item)
    //    Cache[.recentSearches] = NSKeyedArchiver.archivedDataWithRootObject(recentSearches)
  }

  func clearRecentSearches() {
    Cache[.recentSearches] = nil
  }

  func suggestionsForQuery(query: String) -> [SearchItem] {
    return searchEngine.suggestionsForQuery(query)
  }

  func resultsFromSuggestion(suggestion: SearchItem) -> SearchResults? {
    return searchEngine.resultsFromSuggestion(suggestion)
  }
}
