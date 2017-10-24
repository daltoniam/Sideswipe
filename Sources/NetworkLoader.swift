//
//  NetworkLoader.swift
//  iOSTester
//
//  Created by Dalton Cherry on 10/20/17.
//  Copyright © 2017 Vluxe. All rights reserved.
//

import Foundation

public protocol NetworkLoader {
    func get(url: URL, progress: ((Float) -> Void)?, completion: @escaping ((Data?, Error?) -> Void))
}

//really simple default class that uses NSURLSession to fetch images
public class URLSessionLoader: NetworkLoader {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    /**
     This class ignores the progress closure as it is fair amount of work to get that hooked up and there are lots of great network libraries that handle this and would be very simple to implement. See the extras folder for a few implementations of it.
     */
    public func get(url: URL, progress: ((Float) -> Void)? = nil, completion: @escaping ((Data?, Error?) -> Void)) {
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            completion(data, error)
        })
        task.resume()
    }
}
