//
//  AppDelegate.swift
//  LRUCacheApp
//
//  Created by aksc on 22/01/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var context: Context?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let context = Context()
        
        self.context = context
        self.window = UIWindow()
        
        window?.rootViewController = UINavigationController(rootViewController: ViewController(context: context))
        window?.makeKeyAndVisible()
        return true
    }
}

class Context {
    let urlSession: URLSessionProtocol
    let apiManager: APIManagerProtocol
    let cacheManager: CacheManagerProtocol
    let imageDownloader: ImageDownloaderProtocol
    
    init(urlSession: URLSessionProtocol, apiManager: APIManagerProtocol, cacheManager: CacheManagerProtocol, imageDownloader: ImageDownloaderProtocol) {
        self.urlSession = urlSession
        self.apiManager = apiManager
        self.cacheManager = cacheManager
        self.imageDownloader = imageDownloader
    }
    
    convenience init() {
        let urlSession = URLSession.shared
        let apiManager = APIManager(urlSession: urlSession)
        let cacheManager = CacheManager()
        let imageDownloader = ImageDownloader(apiManager: apiManager, cacheManager: cacheManager)
        self.init(urlSession: urlSession,
                  apiManager: apiManager,
                  cacheManager: cacheManager,
                  imageDownloader: imageDownloader)
    }
}
