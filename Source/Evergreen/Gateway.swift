//
//  Gateway.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation
import Alamofire
import os.log

/// `Gateway` represents the endpoint or catalog OSRF server.
class Gateway {

    //MARK: - fields

    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Gateway")
    
    // NOTES ON CACHING
    // ----------------
    // We add 2 parameters to every request to ensure a coherent cache:
    //     _ck=clientCacheKey (the app versionCode)
    //     _sk=serverCacheKey (the server ils-version appended with hemlock.cache_key).
    //
    // In this way we force cache misses in three situations:
    // 1. An app upgrade.
    // 2. A server upgrade.  Server upgrades sometimes involve incompatible IDL which
    //    would otherwise cause OSRF decode crashes.
    // 3. Evergreen admin action.  Changing "hemlock.cache_key" on orgID=1 is a final
    //    override that is needed only to push out org tree or org URL changes immediately.
    static var clientCacheKey: String {
        return Bundle.appVersionUrlSafe
    }
    static var serverCacheKey: String {
        if let val = serverHemlockCacheKey {
            return "\(serverVersionString)-\(val)"
        }
        return serverVersionString
    }
    static var serverVersionString: String = String(CACurrentMediaTime().truncatingRemainder(dividingBy: 1))
    static var serverHemlockCacheKey: String? = nil

    /// an encoding that serializes parameters as param=1&param=2
    static let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)
    
    static let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        let sm = SessionManager(configuration: configuration)
        let delegate = sm.delegate
        delegate.dataTaskWillCacheResponse = { session, dataTask, proposedResponse in
//            var exp: String? = nil
//            // TODO (maybe): implement max TTL for cache
//            if let response = dataTask.response as? HTTPURLResponse,
//                let headers = response.allHeaderFields as? [String:String],
//                let expires = headers["Expires"] {
//                print("Expires: \(expires)")
//                exp = expires
//                print("response: \(response)")
//                //if response.result.isSuccess,
//                //    let data = response.result.value
//                print("stop here")
//            }
//            let size = proposedResponse.data.count
//            print("data: \(proposedResponse.data)")
            if let str = String(data: proposedResponse.data, encoding: .utf8),
                str.contains("\"payload\":[]") {
                // do not cache empty gateway response
                // see also: http://list.evergreen-ils.org/pipermail/evergreen-dev/2021-January/000083.html
                return nil
            }
            //print("willCache: expires:\(exp ?? "") -> \(size) bytes")
            return proposedResponse
        }
        return sm
    }()

    //MARK: - static methods

    /// create an Alamofire request for calling the gateway
    static func makeRequest(service: String, method: String, args: [Any?], shouldCache: Bool) -> Alamofire.DataRequest
    {
        let url = gatewayURL()
        let parameters: [String: Any] = ["service": service, "method": method, "param": gatewayParams(args),
                                         "_ck": clientCacheKey, "_sk": serverCacheKey]
        let request = sessionManager.makeRequest(url, method: shouldCache ? .get : .post, parameters: parameters, encoding: gatewayEncoding, shouldCache: shouldCache)
        let tag = request.request?.debugTag ?? Analytics.nullTag
//        os_log("%@: req.params: %@", log: log, type: .info, tag, parameters.description)
        Analytics.logRequest(tag: tag, method: method, args: gatewayParams(args))
        return request
    }
    
    /// assumes the url already contains cache-busting params if needed
    static func makeRequest(url: String, shouldCache: Bool) -> Alamofire.DataRequest
    {
//        os_log("%s", log: log, type: .info, "url: \(url)")
        return sessionManager.makeRequest(url, shouldCache: shouldCache)
    }

    /// make a request to an OPAC url that mimics a browser session with cookies.
    /// We need this for managing patron messages because there is no OSRF API for it.
    static func makeOPACRequest(url: String, authtoken: String, shouldCache: Bool) -> Alamofire.DataRequest
    {
        let cookie = "ses=\(authtoken); eg_loggedin=1"
        let headers: HTTPHeaders = ["Cookie": cookie]
//        os_log("%s", log: log, type: .info, "url: \(url)")
        return sessionManager.makeRequest(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, shouldCache: shouldCache)
    }

    /// encode params as needed by the gateway
    static func gatewayParams(_ args: [Any?]) -> [String]
    {
        var params: [String] = []
        for opt_arg in args {
            guard let arg = opt_arg else {
                params.append("null")
                continue
            }
            if let s = arg as? String {
                let jsonStr = "\"" + s + "\""
                params.append(jsonStr)
            } else if let d = arg as? Double {
                params.append(String(d))
            } else if let i = arg as? Int {
                params.append(String(i))
            } else if let dict = arg as? [String: Any],
                      let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                      let str = String(data: jsonData, encoding: .utf8)
            {
                params.append(str)
            } else if let obj = arg as? OSRFObject,
                      let jsonData = try? JSONEncoder().encode(obj),
                      let str = String(data: jsonData, encoding: .utf8) {
                params.append(str)
            } else if let jsonData = try? JSONSerialization.data(withJSONObject: arg),
                      let str = String(data: jsonData, encoding: .utf8) {
                params.append(str)
            } else {
                debugPrint(arg)
                fatalError("unhandled arg type, arg = \(arg)")
            }
        }
        return params
    }

    static private func gatewayURL() -> String
    {
        var url = App.library?.url ?? ""
        url += "/osrf-gateway-v1"
        return url
    }

    // NB: The URL returned includes the cache-busting params.
    static func idlURL() -> String {
        var url = App.library?.url ?? ""
        url += "/reports/fm_IDL.xml?"
        var params: [String] = []
        for netClass in API.netClasses.split(separator: ",") {
            params.append("class=" + netClass)
        }
        params.append(contentsOf: cacheParams())
        url += params.joined(separator: "&")
        return url
    }

    static func cacheParams() -> [String] {
        return ["_ck=" + clientCacheKey,
                "_sk=" + serverCacheKey]
    }
    
    static var totalElapsed = 0.0
    @discardableResult
    static func addElapsed(_ elapsed: Double) -> Double {
        //Gateway.reportCacheUsage()
        totalElapsed += elapsed
        return totalElapsed
    }

    static func reportCacheUsage() {
        let diskUsageKB = URLCache.shared.currentDiskUsage / 1024
        let memUsageKB = URLCache.shared.currentMemoryUsage / 1024
        print("cache in mem : \(memUsageKB) kB")
        print("cache on disk: \(diskUsageKB) kB")
    }
}
