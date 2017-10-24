//
//  DataDecoder.swift
//  Sideswipe
//
//  Created by Dalton Cherry on 10/20/17.
//  Copyright © 2017 Vluxe. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import ImageIO
#if os(OSX)
    import CoreServices
    import AppKit
    public typealias Image = NSImage
#else
    import MobileCoreServices
    import UIKit
    public typealias Image = UIImage
#endif

public enum DataDecoderError: Error {
    case invalidData
    case invalidType
    case badAnimatedGif
}

public protocol ImageDecodable {
    
}

public protocol DataDecoder {
    func decode(data: Data, completion: @escaping ((ImageDecodable?, Error?) -> Void))
    var scaleFactor: CGFloat {get}
}

public extension DataDecoder {
    public var scaleFactor: CGFloat {
        #if os(OSX)
            return 1
        #else
            return UIScreen.main.scale
        #endif
    }
}

//decodes the standard image types on iOS & MacOS
open class ImageDecoder: DataDecoder {
    public init() {
    }
    open func decode(data: Data, completion: @escaping ((ImageDecodable?, Error?) -> Void)) {
        guard let ref = CGImageSourceCreateWithData(data as CFData, nil) else {
            completion(nil, DataDecoderError.invalidData)
            return
        }
        guard let imageSourceContainerType = CGImageSourceGetType(ref) else {
            completion(nil, DataDecoderError.invalidType)
            return
        }
        if UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF) {
            let frameCount = CGImageSourceGetCount(ref)
            if frameCount < 2 {
                DispatchQueue.main.sync {
                    let image = Image(data: data, scale: scaleFactor)
                    completion(image, nil)
                }
            } else {
                if let gif = AnimatedGif(ref: ref, data: data, scale: scaleFactor) {
                    completion(gif, nil)
                } else {
                    completion(nil, DataDecoderError.badAnimatedGif)
                }
            }
        } else if UTTypeConformsTo(imageSourceContainerType, kUTTypeImage) {
            DispatchQueue.main.sync {
                let image = Image(data: data, scale: scaleFactor) //UIImage & NSImage are suppose to be thread safe.... but bugs :D
                completion(image, nil)
            }
        }
    }
}

extension Image : ImageDecodable {
    
}
#if os(OSX)
    extension Image {
        convenience init?(data: Data, scale: CGFloat) {
            self.init(data: data)
        }
    }
#endif

public class AnimatedImageFrame {
    let image: Image
    let duration: Double
    init(image: Image, duration: Double) {
        self.image = image
        self.duration = duration
    }
}

public class AnimatedGif : ImageDecodable {
    public var frames = [AnimatedImageFrame]()
    public var images: [Image] {
        return frames.map {$0.image}
    }
    
    init?(ref: CGImageSource, data: Data, scale: CGFloat) {
        let frameCount = CGImageSourceGetCount(ref)
        for i in 0..<frameCount {
            guard let imageRef = CGImageSourceCreateImageAtIndex(ref, i, nil) else {continue}
            guard let frameProps = CGImageSourceCopyPropertiesAtIndex(ref, i, nil) as? [String: AnyObject] else {continue}
            guard let gifProps = frameProps[kCGImagePropertyGIFDictionary as String] as? [String: AnyObject] else {continue}
            guard let rawHeight = gifProps[kCGImagePropertyPixelHeight as String] else {continue}
            guard let rawWidth = gifProps[kCGImagePropertyPixelWidth as String] else {continue}
            guard let height = rawHeight.doubleValue else {continue}
            guard let width = rawWidth.doubleValue else {continue}
            #if os(OSX)
                let size = NSSize(width: width, height: height)
                let img = Image(cgImage: imageRef, size: size)
            #else
                let img = Image(cgImage: imageRef, scale: scale, orientation: .up)
            #endif
            var duration = 0.1
            var delayTime = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String]
            if delayTime == nil {
                delayTime = gifProps[kCGImagePropertyGIFDelayTime as String]
            }
            if let time = delayTime {
                duration = time.doubleValue
            }
            frames.append(AnimatedImageFrame(image: img, duration: duration))
        }
    }
}
