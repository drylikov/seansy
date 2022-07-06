struct Lens<T, U> {
  let from: T -> U
  let to: (U, T) -> T
}
