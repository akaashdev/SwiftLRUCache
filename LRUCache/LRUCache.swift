import Foundation

protocol CacheConfigable {
    var maxCost: Int { get }
    var maxCount: Int { get }
}

public struct CacheConfig: CacheConfigable {
    static let `default` = CacheConfig()
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
    
    public convenience init() {
        self.init(config: CacheConfig.default)
    }
    
    public convenience init(cacheConfig: CacheConfig) {
        self.init(config: cacheConfig)
    }
    
    init(config: CacheConfigable) {
        self.config = config
        let advanceConfig = config as? AdvanceConfig
        list = advanceConfig?.linkedList ?? DoublyLinkedList()
        costProvider = advanceConfig?.costProvider ?? CostProvider()
    }
    
    public func value(for key: Key) -> Item? {
        lock.lock()
        defer { lock.unlock() }
        guard let itemNode = map[key] else { return nil }
        itemNode.updateLastAccessed()
        list.remove(node: itemNode)
        list.append(itemNode)
        return itemNode.item
    }
    
    public func itemInfo(for key: Key) -> ItemMetaData? {
        lock.lock()
        defer { lock.unlock() }
        guard let itemNode = map[key] else { return nil }
        return ItemMetaData(key: itemNode.key,
                            cost: itemNode.cost,
                            createdTime: itemNode.createdTime,
                            lastAccessedTime: itemNode.lastAccessedTime)
    }
    
    public func setItem(_ item: Item, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        let itemNode = ItemNode(key: key, item: item, costProvider: costProvider)
        list.append(itemNode)
        map[key] = itemNode
        totalCost += itemNode.cost
    }
    
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
