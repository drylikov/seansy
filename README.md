<img src=".github/hero.png" alt="Seansy logo" height="70">

Seansy is an iOS app that displays showtimes for movies in Kazakhstan cinemas.

<img src=".github/screenshots.jpg" width="520">

## Stack

The older feature-complete variant of Seansy iOS app is written in Objective-C using the MVC architecture. It's built with [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) and [AFNetworking](https://github.com/AFNetworking/AFNetworking).

The newer feature-incomplete variant of Seansy iOS app is written in Swift 2 using the VIPER architecture. It's built with [RxSwift](https://github.com/ReactiveX/RxSwift), [Alamofire](https://github.com/Alamofire/Alamofire), [Moya](https://github.com/Moya/Moya), [Dip](https://github.com/AliSoftware/Dip), [Stevia](https://github.com/freshOS/Stevia), [Unbox](https://github.com/JohnSundell/Unbox), and [Compass](https://github.com/hyperoslo/Compass).

The Seansy backend is not currently open source.

## Setup

1. Clone the repo:
```console
$ git clone https://github.com/yenbekbay/seansy
$ cd seansy
```

### ios-objc

2. Install iOS app dependencies from [CocoaPods](http://cocoapods.org/#install):
```console
$ (cd ios-objc && bundle install && pod install)
```

3. Configure the secret values for the iOS app:
```console
$ cp ios-objc/Seansy/Secrets-Example.h ios-objc/Seansy/Secrets.h
$ open ios-objc/Seansy/Secrets.h
# Paste your values
```

4. Open the Xcode workspace at `ios-objc/Seansy.xcworkspace` and run the app.

### ios-swift

2. Install iOS app dependencies from [CocoaPods](http://cocoapods.org/#install):
```console
$ (cd ios-swift && bundle install && brew install carthage && pod install && carthage update)
```

3. Configure the secret values for the iOS app:
```console
$ cp ios-swift/Seansy/Secrets-Example.h ios-swift/Seansy/Secrets.h
$ open ios-swift/Seansy/Secrets.h
# Paste your values
```

4. Open the Xcode workspace at `ios-swift/Seansy.xcworkspace` and run the app.

## License

[GNU GPLv3 License](./LICENSE) © Ayan Yenbekbay
