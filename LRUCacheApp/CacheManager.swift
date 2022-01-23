import Foundation
import UIKit
import LRUCache

protocol CacheManagerProtocol {
    typealias CacheStats = (totalHits: Int, cacheHits: Int, hitRate: Float)
    func image(for key: String) -> UIImage?
    func setImage(_ image: UIImage, for key: String)
    func getStats() -> CacheStats
    func toggleCache()
    var isLRUCacheSelected: Bool { get }
}

class CacheManager: CacheManagerProtocol {
    struct Constant {
        static let maxCountLimit = 120
    }
    
    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = Constant.maxCountLimit
        return cache
    }()
    
    private let lruCache: LRUCache<String, UIImage> = {
        let config = CacheConfig(maxCount: Constant.maxCountLimit)
        let cache = LRUCache<String, UIImage>(cacheConfig: config)
        return cache
    }()
    
    private var totalHits = 0
    private var cacheHits = 0
    
    private (set) var isLRUCacheSelected = true {
        didSet {
            guard oldValue != isLRUCacheSelected else { return }
            reset()
        }
    }
    
    func image(for key: String) -> UIImage? {
        let image = isLRUCacheSelected ? lruCache.value(for: key) : cache.object(forKey: key as NSString)
        totalHits += 1
        if image != nil {
            cacheHits += 1
        }
        return image
    }
    
    func setImage(_ image: UIImage, for key: String) {
        isLRUCacheSelected ? lruCache.setItem(image, for: key) : cache.setObject(image, forKey: key as NSString)
    }
    
    func toggleCache() {
        isLRUCacheSelected.toggle()
    }
    
    func getStats() -> CacheStats {
        guard totalHits > 0 else { return (0, 0, 0) }
        return (totalHits, cacheHits, Float(cacheHits) / Float(totalHits))
    }
    
    private func reset() {
        cache.removeAllObjects()
        lruCache.clearAll()
        cacheHits = 0
        totalHits = 0
    }
}
