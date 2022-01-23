# LRUCache App

A **Least Recently Used (LRU) Cache** organizes items in order of use, allowing to quickly identify which item hasn't been used for the longest amount of time which can be purged when cache limits are reached.
This project contains three main targets

- **LRUCache**  *(Static Library)*       -- The main LRUCache logic is available here
- **LRUCacheTests** *(Tests Target)*  -- Unit Test target for LRUCache lib
- **LRUCacheApp** *(App)*                 -- Demo App to show the usage of LRUCache

### Requirements

- Xcode 13.2.1
- Swift 5.2
- Minimum Deploment target - iOS 15.0  (can be made even lower if needed)
- Version control used - Git

## LRUCache

The LRUCache consists of two core files - `LRUCache` and `DoublyLinkedList`. Both are generic classes that can support holding `Key: Hashable` and `Item: Any` types. 
`Node` is the element of the DoublyLinkedList. `ItemNode` is conformed to `Node` protocol and holds the item and the meta-data of the item with the required properies of Node - `next: Node?` and `previous: Node?`

The LRUCache holds a Dictionary (`map`) `[Key: ItemNode]` and a DoublyList (`list`) of `ItemNode`s.
The `map` indexes all the items and the `list` tracks the order of recently used items. The `LRUCache` is reponsible to maintain sync between these two data structures.

#### Methods of `LRUCache`

- `value(for key: Key) -> Item?` 
	 - Returns the cache item if availalbe, else `nil` 
	 - Complexity - **O(1)**
- `itemInfo(for key: Key) -> ItemMetaData?` 
	- Returns the meta-data of the cached item if available, else `nil`
	- Complexity - **O(1)**
- `setItem(_ item: Item, for key: Key)` 
	- Caches the item with the given key
	- Complexity - **O(1)**
- `clearAll()` 	
	- Cleans the cache
	- Complexity - **O(1)**

#### CacheConfig

The LRUCache can be configured with `maxCost` and `maxCount`. The Cache tries to maintain itself within the provided limits. *It purges the most lastly used items accordingly* to acheive this.

There is also `AdvanceCacheConfig` which is **only available internally** within LRUCache lib which is used for injecting dependencies for UnitTests. This can't be accessed from the library consumer.

### Unit Tests

The LRUCache has 100% code coverage.
The testcases can be found in files - `LRUCacheTests.swift` and `DoublyLinkedListTests.swift` of the **LRUCacheTests** target.

## LRUCache App

This is a demo app to see the LRUCache in action. It downloads a list random meme images and shows it in a grid view. The images are cached using both **LRUCache** and **NSCache** depending on the preference.
The **Stats** in more options can be used to compare the difference between **LRUCache** and **Default Cache** (NSCache) performance.