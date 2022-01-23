import Foundation

protocol APIManagerProtocol {
    typealias CompletionResult = Result<Data, Error>
    typealias CompletionHandler = (CompletionResult)->()
    
    func getItems(completion: @escaping CompletionHandler)
    func dowloadImage(from urlString: String, completion: @escaping CompletionHandler)
}

enum RequestError: Error {
    case invalidURL(String)
}

enum ResponseError: Error {
    case nilResponseData
}

class APIManager: APIManagerProtocol {
    private struct API {
        static let itemsEndPoint = "https://api.imgflip.com/get_memes"
    }
    
    let urlSession: URLSessionProtocol
    
    init(urlSession: URLSessionProtocol) {
        self.urlSession = urlSession
    }
    
    private func makeApiCall(urlString: String, completionHandler: @escaping CompletionHandler) {
        guard let url = URL(string: urlString) else {
            print("APIManager: Invalid URL: '\(urlString)'")
            completionHandler(.failure(RequestError.invalidURL(urlString)))
            return
        }
        
        let task = urlSession.makeDataTask(with: url) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            guard let data = data else {
                print("APIManager: Response data nil: \(urlString)")
                completionHandler(.failure(ResponseError.nilResponseData))
                return
            }
            
            completionHandler(.success(data))
        }
        task.resume()
    }
    
    func getItems(completion: @escaping CompletionHandler) {
        makeApiCall(urlString: API.itemsEndPoint, completionHandler: completion)
    }
    
    func dowloadImage(from urlString: String, completion: @escaping CompletionHandler) {
        makeApiCall(urlString: urlString, completionHandler: completion)
    }
}

protocol URLSessionProtocol {
    func makeDataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    func makeDataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return dataTask(with: url, completionHandler: completionHandler)
    }
}
extension URLSessionDataTask: URLSessionDataTaskProtocol { }
