//
//  SwiftHTTPLoader.swift
//  Sideswipe
//
//  Created by Dalton Cherry on 10/23/17.
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
import SwiftHTTP
import Sideswipe

///SwiftHTTP can easily request network queuing and the progress closures!
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
        task.onFinish = { response in
            completion(response.data, response.error)
        }
        queue.add(http: task)
    }
}
