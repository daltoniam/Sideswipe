//
//  ImageManager.swift
//  iOSTester
//
//  Created by Dalton Cherry on 10/20/17.
//  Copyright © 2017 Vluxe. All rights reserved.
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
    static let shared = ImageManager()
    
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


extension ImageView {
    func get(url: URL) {
        ImageManager.shared.get(url: url, completion: { [weak self] (decodable, error) in
            if let img = decodable as? Image {
                self?.image = img
            }
        })
    }
}
