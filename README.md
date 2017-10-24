![sideswipe](https://raw.githubusercontent.com/daltoniam/sideswipe/assets/sideswipe.jpg)

Flexible network image library in Swift. Animated WebP support is also included. 

## Features

- Flexible. Easily swap out network, cache, or image decoding protocols.
- Simple. The flexiblity doesn't come at the cost of simplicity.
- Supports animated images.
- WebP Support.
- MacOS Support.
- Nonblocking. What else would you expect?

## Example

First thing is to import the framework. See the Installation instructions on how to add the framework to your project.

```swift
import Sideswipe
```

Once imported, you can start fetching images. Here is a simple example with a UIImageView.

```swift
let imgView = UIImageView(frame: CGRect(x: 0, y: 65, width: 300, height: 400))
imgView.get(url: URL(string: "http://imgs.xkcd.com/comics/encoding.png")!) 
view.addSubview(imgView)
```

Look at how simple that is. Now for the customization!

### Customization
 
There are 3 major points of customization in Sideswipe. These are 3 different protocols with broken up into network loading, caching, and image data decoding. Swapping out the implementations of these is easily done through the shared `ImageManager` object. Normally this might be done in your AppDelegate.
 
```swift
ImageManager.shared.networkLoader = SwiftHTTPLoader() //use SwiftHTTP instead of the really simple NSURLSession setup. Explained more below.
ImageManager.shared.decoder = WebPDecoder() //use the WebPDecoder to have WebP decoding support
```
 
All the `get` calls to the `UIImageView` or `NSImageView` will use those custom protocol implementations now.

### Extras

Sideswipe provides an `Extras` folders with provides the WebP support and a SwiftHTTP protocol implementation. These are designed to be pulled into the project directly as to avoid having to create a framework dependency nightmare.

## Installation

### CocoaPods

Check out [Get Started](http://cocoapods.org/) tab on [cocoapods.org](http://cocoapods.org/).

To use Starscream in your project add the following 'Podfile' to your project

	source 'https://github.com/CocoaPods/Specs.git'
	platform :ios, '9.0'
	use_frameworks!

	pod 'Sideswipe', '~> 3.0.2'

Then run:

    pod install

### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add a install. The `Sideswipe` framework is already setup with shared schemes.

[Carthage Install](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Starscream into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "daltoniam/Sideswipe" >= 1.0.0
```

### Rogue

First see the [installation docs](https://github.com/acmacalister/Rogue) for how to install Rogue.

To install Starscream run the command below in the directory you created the rogue file.

```
rogue add https://github.com/daltoniam/Sideswipe
```

Next open the `libs` folder and add the `Starscream.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `Sideswipe.framework` to your "Link Binary with Libraries" phase. Make sure to add the `libs` folder to your `.gitignore` file.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding Sideswipe as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .Package(url: "https://github.com/daltoniam/Sideswipe.git", majorVersion: 1)
]
```

### Other

Simply grab the framework (either via git submodule or another package manager).

Add the `Sideswipe.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `Sideswipe.framework` to your "Link Binary with Libraries" phase.

### Add Copy Frameworks Phase

If you are running this in an OSX app or on a physical iOS device you will need to make sure you add the `Sideswipe.framework` to be included in your app bundle. To do this, in Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar. In the tab bar at the top of that window, open the "Build Phases" panel. Expand the "Link Binary with Libraries" group, and add `Sideswipe.framework`. Click on the + button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `Sideswipe.framework` respectively.

## TODOs

- [ ] Add Unit Tests

## License

Sideswipe is licensed under the Apache v2 License.

## Contact

### Dalton Cherry
* https://github.com/daltoniam
* http://twitter.com/daltoniam
* http://daltoniam.com 