// Alamofire cache-ignoring request
//
// courtesy of andrew
// https://stackoverflow.com/questions/32199494/how-to-disable-caching-in-alamofire
// implicitly released under the CC by-SA license

import Alamofire

extension Alamofire.SessionManager{
    @discardableResult
    open func makeRequest(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        shouldCache: Bool)
        -> DataRequest
    {
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            if (shouldCache == false) {
                // NB: by default POST responses are not cached anyway
                urlRequest.cachePolicy = .reloadIgnoringCacheData
            }
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
        } catch {
            return request(url)
        }
    }
}
