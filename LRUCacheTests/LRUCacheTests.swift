import XCTest
@testable import LRUCache

class LRUCacheTests: XCTestCase {
    private typealias Cache = LRUCache<String, FakeFile>
    private var cache: Cache!
    private var list: DoublyLinkedList<Cache.ItemNode>!
    private var costProvider: FakeCostProvider!
    
    override func setUp() {
        super.setUp()
        list = DoublyLinkedList()
        costProvider = FakeCostProvider()
        let config = Cache.AdvanceConfig(maxCost: 10, maxCount: 5, linkedList: list, costProvider: costProvider)
        cache = Cache(config: config)
    }

    func testSetItem() {
        let file1 = FakeFile(cost: 2)
        let file2 = FakeFile(cost: 3)
        
        cache.setItem(file1, for: "file1")
        
        XCTAssertEqual(cache.totalCost, 2)
        XCTAssertIdentical(list.head?.item, file1)
        
        cache.setItem(file2, for: "file2")
        
        XCTAssertEqual(cache.totalCost, 5)
        XCTAssertIdentical(list[1]?.item, file2)
    }
    
    func testPurging_Cost() {
        let file1 = FakeFile(cost: 6)
        let file2 = FakeFile(cost: 2)
        let file3 = FakeFile(cost: 3)
        
        cache.setItem(file1, for: "file1")
        cache.setItem(file2, for: "file2")
        
        XCTAssertEqual(cache.totalCost, 8)
        XCTAssertEqual(list.all.count, 2)
        
        cache.setItem(file3, for: "file3")
        
        XCTAssertEqual(cache.totalCost, 5)
        XCTAssertEqual(list.all.count, 2)
        XCTAssertIdentical(list.head?.item, file2)
        
        let file4 = FakeFile(cost: 2)
        let file5 = FakeFile(cost: 8)
        
        cache.setItem(file4, for: "file4")
        _ = cache.value(for: "file2") // recently accessed
        
        XCTAssertEqual(cache.totalCost, 7)
        XCTAssertEqual(list.all.count, 3)
        XCTAssertIdentical(list.tail?.item, file2) // recently accessed comes to front
        
        cache.setItem(file5, for: "file5")
        
        XCTAssertEqual(cache.totalCost, 10)
        XCTAssertEqual(list.all.count, 2)
        XCTAssertIdentical(list[0]?.item, file2)
        XCTAssertIdentical(list[1]?.item, file5)
    }
    
    func testPurging_Count() {
        let file1 = FakeFile(cost: 1)
        let file2 = FakeFile(cost: 1)
        let file3 = FakeFile(cost: 1)
        let file4 = FakeFile(cost: 1)
        let file5 = FakeFile(cost: 1)
        let file6 = FakeFile(cost: 1)
        
        cache.setItem(file1, for: "file1")
        cache.setItem(file2, for: "file2")
        cache.setItem(file3, for: "file3")
        cache.setItem(file4, for: "file4")
        cache.setItem(file5, for: "file5")
        
        XCTAssertEqual(cache.totalCost, 5)
        XCTAssertEqual(list.all.count, 5)
        XCTAssertIdentical(list.head?.item, file1)
        XCTAssertIdentical(list.tail?.item, file5)
        
        cache.setItem(file6, for: "file6")
        
        XCTAssertEqual(cache.totalCost, 5)
        XCTAssertEqual(list.all.count, 5)
        XCTAssertIdentical(list.head?.item, file2)
        XCTAssertIdentical(list.tail?.item, file6)
        
        _ = cache.value(for: "file2") // recently accessed
        cache.setItem(file1, for: "file1")
        
        XCTAssertEqual(cache.totalCost, 5)
        XCTAssertEqual(list.all.count, 5)
        XCTAssertIdentical(list.tail?.item, file1)
        XCTAssertIdentical(list[3]?.item, file2)
        XCTAssertIdentical(list[0]?.item, file4)
    }
    
    func testValueFor() throws {
        let file1 = FakeFile(cost: 1)
        let file2 = FakeFile(cost: 1)
        let file3 = FakeFile(cost: 1)
        
        cache.setItem(file1, for: "file1")
        cache.setItem(file2, for: "file2")
        cache.setItem(file3, for: "file3")
        
        XCTAssertIdentical(list.head?.item, file1)
        let accessTimeFile1 = try XCTUnwrap(list.head?.lastAccessedTime)
        
        let result = cache.value(for: "file1")
        XCTAssertIdentical(result, file1)
        
        XCTAssertIdentical(list.tail?.item, file1) // recently used. moves behind
        let newAccessTimeFile1 = try XCTUnwrap(list.tail?.lastAccessedTime)
        XCTAssertGreaterThan(newAccessTimeFile1.timeIntervalSince1970, accessTimeFile1.timeIntervalSince1970)
        
        let result2 = cache.value(for: "file3")
        XCTAssertIdentical(result2, file3)
    }
    
    func testItemInfo() throws {
        let file1 = FakeFile(cost: 1)
        let file2 = FakeFile(cost: 1)
        let file3 = FakeFile(cost: 1)
        
        cache.setItem(file1, for: "file1")
        cache.setItem(file2, for: "file2")
        cache.setItem(file3, for: "file3")
        
        let result = try XCTUnwrap(cache.itemInfo(for: "file2"))
        
        XCTAssertIdentical(list.tail?.item, file3) // accessing info shouldn't modify recently used
        XCTAssertIdentical(list[1]?.item, file2)
        
        XCTAssertEqual(result.lastAccessedTime, list[1]?.lastAccessedTime)
        XCTAssertEqual(result.key, list[1]?.key)
        XCTAssertEqual(result.cost, list[1]?.cost)
        XCTAssertEqual(result.createdTime, list[1]?.createdTime)
    }
}

private class FakeFile: CustomStringConvertible {
    let id: String
    let cost: Int
    
    init(cost: Int = 0) {
        self.id = UUID().uuidString
        self.cost = cost
    }
    
    var description: String {
        return "File \(id) -- cost \(cost)"
    }
}

private class FakeCostProvider: CostProviderProtocol {
    var sizeToReturn = 0
    func size(of value: Any) -> Int {
        if let file = value as? FakeFile { return file.cost }
        return sizeToReturn
    }
}
