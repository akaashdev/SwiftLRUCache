@testable import LRUCache
import XCTest

class DoublyLinkedListTests: XCTestCase {
    private var list: DoublyLinkedList<FakeNode>!
    
    override func setUp() {
        super.setUp()
        list = DoublyLinkedList()
    }
    
    func testSubscripts() {
        prepareList([1, 2, 3, 4, 5])
        let items = list.all
        
        XCTAssertEqual(list[0], 1)
        XCTAssertEqual(list[1], 2)
        XCTAssertEqual(list[2], 3)
        XCTAssertEqual(list[3], 4)
        XCTAssertEqual(list[4], 5)
        
        XCTAssertEqual(items[0], 1)
        XCTAssertEqual(items[1], 2)
        XCTAssertEqual(items[2], 3)
        XCTAssertEqual(items[3], 4)
        XCTAssertEqual(items[4], 5)
    }
    
    func testAppendFirstItem() {
        XCTAssertTrue(list.isEmpty)
        XCTAssertNil(list.head)
        XCTAssertNil(list.tail)
        
        list.append(24)
        
        XCTAssertFalse(list.isEmpty)
        XCTAssertNotNil(list.head)
        XCTAssertNotNil(list.tail)
        XCTAssertEqual(list.head, list.tail)
    }
    
    func testAppend() {
        list.append(12)
        list.append(24)
        list.append(12)
        list.append(12)
        
        verifySequence([12, 24, 12, 12])
    }
    
    func testRemove() throws {
        prepareList([1, 2, 3])
        let first = try XCTUnwrap(list[0])
        let middle = try XCTUnwrap(list[1])
        let last = try XCTUnwrap(list[2])
        
        list.remove(node: middle)
        verifySequence([1, 3])
        XCTAssertIdentical(first, list.head)
        XCTAssertIdentical(last, list.tail)
        
        list.remove(node: first)
        verifySequence([3])
        XCTAssertIdentical(last, list.head)
        XCTAssertIdentical(last, list.tail)
        
        list.remove(node: last)
        verifySequence([])
        XCTAssertTrue(list.isEmpty)
        XCTAssertNil(list.tail)
        XCTAssertNil(list.head)
    }
    
    func testRemoveLast() throws {
        prepareList([5, 4, 2, 1])
        
        var node = list.dropFirst()
        verifySequence([4, 2, 1])
        XCTAssertEqual(list.head?.value, 4)
        XCTAssertEqual(list.tail?.value, 1)
        XCTAssertEqual(node?.value, 5)
        
        node = list.dropFirst()
        verifySequence([2, 1])
        XCTAssertEqual(list.head?.value, 2)
        XCTAssertEqual(list.tail?.value, 1)
        XCTAssertEqual(node?.value, 4)
        
        node = list.dropFirst()
        verifySequence([1])
        XCTAssertEqual(list.head?.value, 1)
        XCTAssertEqual(list.tail?.value, 1)
        XCTAssertEqual(node?.value, 2)
        
        node = list.dropFirst()
        verifySequence([])
        XCTAssertNil(list.head)
        XCTAssertNil(list.tail)
        XCTAssertEqual(node?.value, 1)
    }
    
    private func prepareList(_ seq: [Int]) {
        seq.forEach { list.append(FakeNode(integerLiteral: $0)) }
    }
    
    private func verifySequence(_ seq: [Int]) {
        for i in (0 ..< seq.count) {
            XCTAssertEqual(list[i]?.value, seq[i], "wrong at index \(i)")
        }
    }
}

private final class FakeNode: Node, ExpressibleByIntegerLiteral, Equatable {
    var next: FakeNode?
    var previous: FakeNode?
    let value: Int
    
    init(integerLiteral value: Int) {
        self.value = value
    }
    
    static func == (lhs: FakeNode, rhs: FakeNode) -> Bool {
        return lhs.value == rhs.value
    }
}

// Helper method
extension DoublyLinkedList {
    subscript(index: Int) -> T? {
        var i = 0
        var ptr = head
        while i < index {
            guard let next = ptr?.next else { return nil }
            i += 1
            ptr = next
        }
        return ptr
    }
    
    var all: [T] {
        var items: [T] = []
        var ptr = head
        while let node = ptr {
            items.append(node)
            ptr = node.next
        }
        return items
    }
}
