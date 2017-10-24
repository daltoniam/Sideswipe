//
//  SwiftHTTPLoader.swift
//  iOSTester
//
//  Created by Dalton Cherry on 10/23/17.
//  Copyright © 2017 Vluxe. All rights reserved.
//

import Foundation
import SwiftHTTP

//really simple default class that uses NSURLSession to fetch images
public class SwiftHTTPLoader: NetworkLoader {
    private let queue = HTTPQueue(maxSimultaneousRequest: 8)
    public var maxSimultaneousRequest = 8 {
        didSet {
            queue.maxSimultaneousRequest = maxSimultaneousRequest
        }
    }
    
    public func get(url: URL, progress: ((Float) -> Void)? = nil, completion: @escaping ((Data?, Error?) -> Void)) {
        let request = URLRequest(url: url)
        let task = HTTP(request)
        task.progress = { value in
            progress?(value)
        }
        queue.add(http: task)
    }
}
