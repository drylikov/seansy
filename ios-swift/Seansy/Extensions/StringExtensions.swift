extension String {
  subscript(range: Range<Int>) -> String {
    get {
      let startIndex = self.startIndex.advancedBy(range.startIndex)
      let endIndex = self.startIndex.advancedBy(range.endIndex)

      return self[startIndex..<endIndex]
    }
  }
  subscript(index: Int) -> Character {
    get { return self[startIndex.advancedBy(index)] }
  }

  func size(font: UIFont, size: CGSize? = nil) -> CGSize {
    if let size = size {
      return (self as NSString)
        .boundingRectWithSize(size,
          options: .UsesLineFragmentOrigin,
          attributes: [
            NSParagraphStyleAttributeName: NSMutableParagraphStyle().then { $0.lineBreakMode = .ByWordWrapping },
            NSFontAttributeName: font
          ],
          context: nil
        ).size
    } else {
      return (self as NSString).sizeWithAttributes([ NSFontAttributeName: font ])
    }
  }

  func uppercaseFirstChar() -> String {
    return stringByReplacingCharactersInRange(lowercaseString.startIndex...lowercaseString.startIndex,
      withString: String(self[0]).uppercaseString)
  }

  func score(word: String, fuzziness: Double? = nil) -> Double {
    if self == word { return 1 }
    if isEmpty || word.isEmpty { return 0 }

    let lString = lowercaseString
    let lWord = word.lowercaseString
    let wordLength = word.length

    var (runningScore, charScore, finalScore) = (0.0, 0.0, 0.0)
    var (fuzzies, fuzzyFactor, fuzzinessIsNil) = (1.0, 0.0, true)

    var idxOf: String.Index!
    var startAt = lString.startIndex

    if let fuzziness = fuzziness {
      fuzzyFactor = 1 - fuzziness
      fuzzinessIsNil = false
    }

    for i in 0..<wordLength {
      // Find next first case-insensitive match of word's i-th character
      // The search in "string" begins at "startAt"
      if let range = lString
        .rangeOfString(String(lWord[i]), options: .CaseInsensitiveSearch, range: startAt..<lString.endIndex) {
          // Start index of word's i-th character in string
          idxOf = range.startIndex
          if startAt == idxOf {
            // Consecutive letter & start-of-string bonus
            charScore = 0.7
          } else {
            charScore = 0.1

            // Acronym bonus
            // Weighing logic: typing the first character of an acronym is as if you
            // preceded it with two perfect character matches
            if string[idxOf.advancedBy(-1)] == " " { charScore += 0.8 }
          }
      } else {
        // Character not found
        if fuzzinessIsNil {
          return 0
        } else {
          fuzzies += fuzzyFactor
          continue
        }
      }

      // Same case bonus
      if string[idxOf] == word[i] { charScore += 0.1 }

      // Update scores and startAt position for next round of indexOf
      runningScore += charScore
      startAt = idxOf.advancedBy(1)
    }

    // Reduce penalty for longer strings.
    finalScore = 0.5 * (runningScore / Double(length) + runningScore / Double(wordLength)) / fuzzies

    if lWord[0] == lString[0] && finalScore < 0.85 { finalScore += 0.15 }

    return finalScore
  }
}

extension NSAttributedString {
  func size(size: CGSize? = nil) -> CGSize {
    return boundingRectWithSize(size ?? CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
      options: .UsesLineFragmentOrigin, context: nil).size
  }
}
