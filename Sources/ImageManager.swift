//
//  ImageManager.swift
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
#if os(OSX)
    import AppKit
    public typealias ImageView = NSImageView
#else
    import UIKit
    public typealias ImageView = UIImageView
#endif

public protocol ImageManagerClient: class {
    func get(url: URL, progress: ((Float) -> Void)?, completion: @escaping ((ImageDecodable?, Error?) -> Void))
}

public class ImageManager: ImageManagerClient {
    public static let shared = ImageManager()
    
    public var networkLoader: NetworkLoader = URLSessionLoader()
    public var cache: Cache = SimpleCache()
    public var decoder: DataDecoder = ImageDecoder()
    
    public func get(url: URL, progress: ((Float) -> Void)? = nil, completion: @escaping ((ImageDecodable?, Error?) -> Void)) {
        cache.get(url: url, completion: {[weak self] (data) in
            if let d = data {
                DispatchQueue.main.async {
                    progress?(1)
                }
                self?.processData(data: d, completion: completion)
            } else {
                self?.networkLoader.get(url: url, progress: progress, completion: { [weak self] (data, error) in
                    if let d = data {
                        self?.cache.save(url: url, data: d)
                        self?.processData(data: d, completion: completion)
                    }
                })
            }
        })
    }
    
    func processData(data: Data, completion: @escaping ((ImageDecodable?, Error?) -> Void)) {
        decoder.decode(data: data, completion: { (image, error) in
            DispatchQueue.main.async {
                completion(image, error)
            }
        })
    }
}


public extension ImageView {
    public func get(url: URL) {
        ImageManager.shared.get(url: url, completion: { [weak self] (decodable, error) in
            if let img = decodable as? Image {
                self?.image = img
            }
        })
    }
}
