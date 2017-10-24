//
//  WebPDecoder.swift
//  iOSTester
//
//  Created by Dalton Cherry on 10/23/17.
//  Copyright © 2017 Vluxe. All rights reserved.
//

import Foundation
import WebP

public class WebPDecoder: ImageDecoder {
    ///This subclasses ImageDecoder so it can decode both WebP and standard images images
    public override func decode(data: Data, completion: ((ImageDecodable?, Error?) -> Void)) {
        WebP.WebPConfig
        let config = WebPConfig()
        config.test()
        
//        if WebPGetInfo(data.bytes, data.length, nil, nil) {
//
//        }
    }
}
