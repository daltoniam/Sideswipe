//
//  Cache.swift
//  iOSTester
//
//  Created by Dalton Cherry on 10/20/17.
//  Copyright © 2017 Vluxe. All rights reserved.
//

import Foundation

public protocol Cache {
    func get(url: URL, completion: @escaping ((Data?) -> Void)) //get an image out of the cache asynchronously
    func save(url: URL, data: Data) //save an image to the cache
    func clean() ///clean up any old data. Useful for disk caches that could have old files laying around
    func purge() ///purge the cache
}

//really simple default cache to save images. Memory and disk caching included.
public class SimpleCache: Cache {
    var memoryCache: Cache = SimpleMemoryCache()
    var diskCache: Cache = SimpleDiskCache()
    
    init() {
    }
    
    public func get(url: URL, completion: @escaping ((Data?) -> Void)) {
        memoryCache.get(url: url) {[weak self] (data) in
            if let d = data {
                completion(d)
            } else {
                self?.diskCache.get(url: url) {[weak self] (data) in
                    if let d = data {
                        self?.memoryCache.save(url: url, data: d)
                    }
                    completion(data)
                }
            }
        }
    }
    
    public func save(url: URL, data: Data) {
        memoryCache.save(url: url, data: data)
        diskCache.save(url: url, data: data)
    }
    
    public func clean() {
        memoryCache.clean()
        diskCache.clean()
    }
    
    public func purge() {
        memoryCache.purge()
    }
}

//Least Recently Used (LRU) memory cache
public class SimpleMemoryCache: Cache {
    
    private var map = [Int: Node<Data>]()
    private let list = LinkedList<Data>()
    private let mutex = NSLock()
    
    ///the amount of images to store in memory before pruning
    public var imageCount = 50
    
    init() {
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.addObserver(self, selector: #selector(memoryWarning), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
        #endif
    }
    
    public func get(url: URL, completion: @escaping ((Data?) -> Void)) {
        let hash = hashFrom(url: url)
        mutex.lock()
        if let node = map[hash] {
            list.moveToFront(node)
            mutex.unlock()
            completion(node.value)
        } else {
            mutex.unlock()
            completion(nil)
        }
    }
    
    public func save(url: URL, data: Data) {
        let hash = hashFrom(url: url)
        mutex.lock()
        if let node = map[hash] {
            list.moveToFront(node)
        } else {
            let node = Node(value: data, hash: hash)
            map[hash] = node
            list.append(node)
        }
        mutex.unlock()
        prune()
    }
    
    public func clean() {
        prune()
    }
    
    public func purge() {
        mutex.lock()
        list.removeAll()
        map.removeAll()
        mutex.unlock()
    }
    
    func prune() {
        mutex.lock()
        while map.count > imageCount {
            guard let node = list.pop() else {break}
            map.removeValue(forKey: node.hash)
        }
        mutex.unlock()
    }
    
    func hashFrom(url: URL) -> Int {
        return url.hashValue
    }
    
    @objc func memoryWarning() {
        purge()
    }
    
    deinit {
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.removeObserver(self)
        #endif
    }
}

//Async saving and reading of image data from the cache directory.
public class SimpleDiskCache: Cache {
    ///the length of time a image is saved to disk before it expires (int seconds).
    public var timeoutAge: Int
    
    ///the directory to be used for saving images to disk
    public var cacheDirectory: String
    
    /**
     cacheDirectory default is the device's cache directory
     timeoutAge default is 24 hours
     */
    init(cacheDirectory: String = SimpleDiskCache.defaultDirectory(), timeoutAge: Int = 60 * 60 * 24) {
        self.cacheDirectory = cacheDirectory
        self.timeoutAge = timeoutAge
    }
    
    class func defaultDirectory() -> String {
        var directory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        #if os(OSX)
            if let name = Bundle.main.bundleIdentifier {
                directory += "/\(name)"
            }
        #endif
        directory += "/ImageCache"
        return directory
    }
    
    public func get(url: URL, completion: @escaping ((Data?) -> Void)) {
        let hash = hashFrom(url: url)
        let cachePath = "\(cacheDirectory)/\(hash)"
        DispatchQueue.global(qos: .background).async {
            self.createCacheDirectory()
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: cachePath) {
                completion(nil)
                return
            }
            do {
                let attrs = try fileManager.attributesOfItem(atPath: cachePath)
                let modifyDate = attrs[FileAttributeKey.modificationDate] as! Date
                let expireDate = Date(timeIntervalSinceNow: TimeInterval(-self.timeoutAge))
                if modifyDate > expireDate {
                    completion(nil)
                    return
                }
                let data = fileManager.contents(atPath: cachePath)
                completion(data)
            } catch {
                completion(nil)
            }
        }
    }
    
    public func save(url: URL, data: Data) {
        let hash = hashFrom(url: url)
        let cachePath = "\(cacheDirectory)/\(hash)"
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: cachePath)
            } catch {}
            let fileUrl = URL(fileURLWithPath: cachePath)
            do {
                try data.write(to: fileUrl)
            } catch {}
        }
    }
    
    public func clean() {
        let resourceKeys : [URLResourceKey] = [.contentModificationDateKey]
        let directory = URL(fileURLWithPath: cacheDirectory)
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: resourceKeys) else {return}
            for case let fileURL as URL in enumerator {
                do {
                    let attrs = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    guard let modifyDate = attrs.attributeModificationDate else {continue}
                    let expireDate = Date(timeIntervalSinceNow: TimeInterval(-self.timeoutAge))
                    if modifyDate > expireDate {
                         try fileManager.removeItem(at: fileURL)
                    }
                } catch {
                    
                }
            }
        }
    }
    
    public func purge() {
        let directory = cacheDirectory
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(atPath: directory) else {return}
            for case let fileURL as URL in enumerator {
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    
                }
            }
        }
    }
    
    func hashFrom(url: URL) -> Int {
        return url.hashValue
    }
    
    ///create the cacheDirectory folder if it does not exist
    private func createCacheDirectory() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cacheDirectory) {
            do {
            try fileManager.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                
            }
        }
    }
}


/// Basic doubly linked list with a few optimizations for usage as a LRU.
private final class LinkedList<V> {
    private(set) var head: Node<V>?
    private(set) var tail: Node<V>?
    
    func append(_ node: Node<V>) {
        if let currentHead = head {
            head = node
            currentHead.previous = node
            node.next = currentHead
        } else {
            head = node
            tail = node
        }
    }
    
    func moveToFront(_ node: Node<V>) {
        let prev = node.previous
        node.next?.previous = node.previous
        prev?.next = node.next
        node.next = nil
        node.previous = nil
        append(node)
    }
    
    func remove(_ node: Node<V>) {
        node.next?.previous = node.previous // node.previous is nil if node=head
        node.previous?.next = node.next // node.next is nil if node=tail
        if node === head { head = node.next }
        if node === tail { tail = node.previous }
        node.next = nil
        node.previous = nil
    }
    
    func pop() -> Node<V>? {
        guard let node = tail else {return nil}
        tail = node.previous
        node.previous?.next = nil
        node.previous = nil
        return node
    }
    
    func removeAll() {
        var node = tail
        while let previous = node?.previous {
            previous.next = nil
            node = previous
        }
        head = nil
        tail = nil
    }
    
    deinit {
        removeAll()
    }
}

private final class Node<V> {
    let value: V
    let hash: Int
    var next: Node<V>?
    weak var previous: Node<V>?
    
    init(value: V, hash: Int) {
        self.value = value
        self.hash = hash
    }
}

