import UIKit

class ViewController: UICollectionViewController {
    private let apiManager: APIManagerProtocol
    private let cacheManager: CacheManagerProtocol
    private let imageDownloader: ImageDownloaderProtocol
    
    private var items: [String] = []
    
    init(context: Context) {
        apiManager = context.apiManager
        cacheManager = context.cacheManager
        imageDownloader = context.imageDownloader
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.itemSize = CGSize(width: 180, height: 180)
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LRU Cache"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: UIMenu(children: [
                            UIAction(title: "Toggle Cache",
                                     handler: { _ in self.toggleCache() }),
                            UIAction(title: "Show Stats",
                                     handler: { _ in self.showCacheStats()})
                         ])
        )
        collectionView.register(ImageCellView.self, forCellWithReuseIdentifier: "cell")
        loadItems()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ImageCellView else { return UICollectionViewCell() }
        cell.setup(with: items[indexPath.item], downloader: imageDownloader)
        return cell
    }
    
    private func loadItems() {
        apiManager.getItems { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
                      let dict = json as? [String: Any],
                      let dataDict = dict["data"] as? [String: Any],
                      let memes = dataDict["memes"] as? [[String: Any]]
                else {
                    print("JSON parse error")
                    return
                }
                
                let urls = memes.compactMap { $0["url"] as? String }
                self.items = urls + urls + urls // to simulate more items are redundancy
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            case .failure(let error):
                print("API Call failed with error - ", error.localizedDescription)
            }
        }
    }
    
    private func toggleCache() {
        cacheManager.toggleCache()
        title = cacheManager.isLRUCacheSelected ? "LRU Cache" : "Default Cache"
    }
    
    private func showCacheStats() {
        let stats = cacheManager.getStats()
        let content = """
        Type           - \(cacheManager.isLRUCacheSelected ? "LRUCache" : "NSCache")
        Total Hits     - \(stats.totalHits)
        Cache Hits     - \(stats.cacheHits)
        Cache Hit Rate - \(stats.hitRate * 100)%
        """
        let alert = UIAlertController(title: "Cache Stats", message: content, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        present(alert, animated: true)
    }
}

class ImageCellView: UICollectionViewCell {
    private var currentURL: String?
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    func setup(with url: String, downloader: ImageDownloaderProtocol) {
        currentURL = url
        downloader.downloadImage(from: url) { [weak self] result in
            guard let self = self,
                  let imageInfo = try? result.get(),
                  self.currentURL == imageInfo.url
            else { return }
            self.imageView.image = imageInfo.image
        }
    }
}
