//
//  WebPDecoder.swift
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
import WebP
import Sideswipe

extension AnimatedWebPImage : ImageDecodable {
    
}

open class WebPDecoder: ImageDecoder {
    
    override init() {
        super.init()
    }
    
    ///This subclasses ImageDecoder so it can decode both WebP and standard images images
    open override func decode(data: Data, completion: @escaping ((ImageDecodable?, Error?) -> Void)) {
        let scale = scaleFactor
        DispatchQueue.global().async {
            let result = WebP.decode(data: data, scale: scale)
            if let img = result as? AnimatedWebPImage {
                completion(img, nil)
            } else if let img = result as? Image {
                completion(img, nil)
            } else {
                super.decode(data: data, completion: completion)
            }
        }
    }
}
