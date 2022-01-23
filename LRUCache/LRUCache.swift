import Foundation

protocol CacheConfigable {
    var maxCost: Int { get }
    var maxCount: Int { get }
}

/**
 The struct used to configure the LRUCache
 
 - Parameter maxCost : Tells the maximum memory allowed to the cache
 - Parameter maxCount : Tells the maximum limit of items the cache and hold
 **/
public struct CacheConfig: CacheConfigable {
    public static let `default` = CacheConfig()
    let maxCost: Int
    let maxCount: Int
    
    public init(maxCost: Int = .max, maxCount: Int = .max) {
        self.maxCost = maxCost
        self.maxCount = maxCount
    }
}

protocol CostProviderProtocol {
    func size(of value: Any) -> Int
}

class CostProvider: CostProviderProtocol {
    func size(of value: Any) -> Int {
        return MemoryLayout.size(ofValue: value)
    }
}

public class LRUCache<Key: Hashable, Item> {
    let config: CacheConfigable
    
    private let costProvider: CostProviderProtocol
    private let list: DoublyLinkedList<ItemNode>
    private let lock: NSLock = NSLock()
    private var map: [Key: ItemNode] = [:]
    
    private (set) var totalCost: Int = 0 {
        didSet { purge() }
    }
    
    /**
     Initializes a new LRUCache with the provided `CacheConfig`
     
     - Parameter cacheConfig : The configuration of the cache. Takes maximum limits by default.
     **/
    public convenience init(cacheConfig: CacheConfig = .default) {
        self.init(config: cacheConfig)
    }
    
    init(config: CacheConfigable) {
        self.config = config
        let advanceConfig = config as? AdvanceConfig
        list = advanceConfig?.linkedList ?? DoublyLinkedList()
        costProvider = advanceConfig?.costProvider ?? CostProvider()
    }
    
    /**
     Returns the cached `Item` for the given `Key`
     
     - Parameter key : The `Key` the item is mapped with
     - Returns : The cached `Item` for the given `Key` if available, else returns `nil`
     - Complexity : O(1)
     **/
    public func value(for key: Key) -> Item? {
        lock.lock()
        defer { lock.unlock() }
        guard let itemNode = map[key] else { return nil }
        itemNode.updateLastAccessed()
        list.remove(node: itemNode)
        list.append(itemNode)
        return itemNode.item
    }
    
    /**
     Returns the additonal informations of the cached `Item` for the given `Key`
     
     - Parameter key : The `Key` the item is mapped with
     - Returns : `ItemMetaData` for the given `Key` if available, else returns `nil`
     - Complexity : O(1)
     **/
    public func itemInfo(for key: Key) -> ItemMetaData? {
        lock.lock()
        defer { lock.unlock() }
        guard let itemNode = map[key] else { return nil }
        return ItemMetaData(key: itemNode.key,
                            cost: itemNode.cost,
                            createdTime: itemNode.createdTime,
                            lastAccessedTime: itemNode.lastAccessedTime)
    }
    
    /**
     Caches the provided `Item` with the provided `Key`
     
     - Parameter item : The `Item` that need to be cached
     - Parameter key : The `Key` the item needs to be mapped with 
     - Complexity : O(1)
     **/
    public func setItem(_ item: Item, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        let itemNode = ItemNode(key: key, item: item, costProvider: costProvider)
        list.append(itemNode)
        map[key] = itemNode
        totalCost += itemNode.cost
    }
    
    /**
     Clears the cache by removing all the items
     - Complexity : O(1)
     **/
    public func clearAll() {
        lock.lock()
        map.removeAll()
        list.removeAll()
        lock.unlock()
    }
    
    private func purge() {
        guard totalCost > config.maxCost || map.count > config.maxCount else { return }
        guard let item = list.dropFirst() else { return }
        map[item.key] = nil
        totalCost -= item.cost
    }
}

extension LRUCache {
    final class ItemNode: Node {
        let key: Key
        let item: Item
        let cost: Int
        let createdTime: Date
        var lastAccessedTime: Date
        var next: ItemNode?
        weak var previous: ItemNode?
        
        init(key: Key, item: Item, costProvider: CostProviderProtocol) {
            self.key = key
            self.item = item
            createdTime = Date()
            lastAccessedTime = createdTime
            cost = costProvider.size(of: item)
        }
        
        func updateLastAccessed() {
            lastAccessedTime = Date()
        }
    }
    
    struct AdvanceConfig: CacheConfigable {
        let maxCost: Int
        let maxCount: Int
        let linkedList: DoublyLinkedList<ItemNode>
        let costProvider: CostProviderProtocol
    }
    
    public struct ItemMetaData {
        let key: Key
        let cost: Int
        let createdTime: Date
        let lastAccessedTime: Date
    }
}
