// Alamofire cache-ignoring request
//
// courtesy of andrew
// https://stackoverflow.com/questions/32199494/how-to-disable-caching-in-alamofire
// implicitly released under the CC by-SA license

import Alamofire

extension Alamofire.SessionManager{
    @discardableResult
    open func requestWithoutCache(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)// also you can add URLRequest.CachePolicy here as parameter
        throws -> DataRequest
    {
//        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            urlRequest.cachePolicy = .reloadIgnoringCacheData // <<== Cache disabled
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
//        } catch {
//            // TODO: find a better way to handle error
//            print(error)
//            return request(URLRequest(url: URL(string: "http://example.com/wrong_request")!))
//        }
    }
}
