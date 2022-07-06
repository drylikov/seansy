extension Int {
  func pluralize(endings: [String]) -> String {
    let number = self % 100
    if abs(self) == 1 {
      return "\(self) \(endings[0])"
    } else if number >= 11 && number <= 19 {
      return "\(self) \(endings[2])"
    } else {
      switch number % 10 {
      case 1:
        return "\(self) \(endings[0])"
      case 2, 3, 4:
        return "\(self) \(endings[1])"
      default:
        return "\(self) \(endings[2])"
      }
    }
  }
}
