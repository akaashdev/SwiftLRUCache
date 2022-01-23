import UIKit

protocol ImageDownloaderProtocol: AnyObject {
    typealias ImageDetails = (url: String, image: UIImage)
    typealias ImageDownloadResult = Result<ImageDetails, Error>
    typealias ImageDownloadCompletion = (ImageDownloadResult)->()
    
    var apiManager: APIManagerProtocol { get }
    func downloadImage(from urlString: String, completion: ImageDownloadCompletion?)
}

enum ImageDownloadError: Error {
    case imageDataConversionFailed
}

class ImageDownloader: ImageDownloaderProtocol {
    let apiManager: APIManagerProtocol
    let cacheManager: CacheManagerProtocol
    
    init(apiManager: APIManagerProtocol, cacheManager: CacheManagerProtocol) {
        self.apiManager = apiManager
        self.cacheManager = cacheManager
    }
    
    func downloadImage(from urlString: String, completion: ImageDownloadCompletion?) {
        if let cachedImage = cacheManager.image(for: urlString) {
            completion?(.success((urlString, cachedImage)))
            return
        }
        
        func complete(with error: Error) {
            DispatchQueue.main.async { completion?(.failure(error)) }
        }
        
        apiManager.dowloadImage(from: urlString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(data):
                guard let origImage = UIImage(data: data),
                      let image = origImage.resizeImage(targetSize: CGSize(width: 180, height: 180)) // downscaling for performance
                else {
                    complete(with: ImageDownloadError.imageDataConversionFailed)
                    return
                }
                self.cacheManager.setImage(image, for: urlString)
                DispatchQueue.main.async { completion?(.success((urlString, image))) }
                
            case let .failure(error):
                complete(with: error)
            }
        }
    }
}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage? {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
