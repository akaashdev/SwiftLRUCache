import Foundation

protocol Node: AnyObject {
    var next: Self? { get set }
    var previous: Self? { get set }
}

class DoublyLinkedList<T: Node> {
    private (set) var head: T?
    private (set) var tail: T?
    
    var isEmpty: Bool {
        guard head == nil else { return false }
        assert(tail == nil) // tail should be nil when head is nil
        return true
    }

    func append(_ node: T) {
        guard !isEmpty, let tailNode = tail else {
            head = node
            tail = node
            return
        }
        tailNode.next = node
        node.previous = tailNode
        self.tail = node
    }
    
    func remove(node: T) {
        if node === head { head = node.next }
        if node === tail { tail = node.previous }
        node.previous?.next = node.next
        node.next?.previous = node.previous
        node.next = nil
        node.previous = nil
    }
    
    @discardableResult
    func dropFirst() -> T? {
        guard !isEmpty, let head = head else { return nil }
        remove(node: head)
        return head
    }
}
