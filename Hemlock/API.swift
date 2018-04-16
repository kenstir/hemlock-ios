//
//  API.swift
//  Hemlock
//
//  Created by Ken Cox on 4/8/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation
import Alamofire

struct API {
    // endpoints
    static let directoryURL = "https://evergreen-ils.org/directory/libraries.json"

    // auth service
    static let auth = "open-ils.auth"
    static let authInit = "open-ils.auth.authenticate.init"
    static let authComplete = "open-ils.auth.authenticate.complete"
    static let authGetSession = "open-ils.auth.session.retrieve"

    static var library: Library?
    
    func createRequest(service: String, method: String, args: [Any]) -> Alamofire.Request
    {
        let url = API.gatewayURL(service: service, method: method, args: args)
        let request = Alamofire.request(url)
        return request
    }
    
    // serialize an HTTP param
    static func gatewayParam(_ arg: Any) -> String
    {
        var ret: String
        if arg is String {
            ret = "\"\(arg)\""
        } else if arg is Double {
            ret = "\(arg)"
        } else if arg is Int {
            ret = "\(arg)"
        } else {
            ret = ""
        }
        return ret
    }
    
    static func gatewayURL(service: String, method: String, args: [Any]) -> String
    {
        guard var url = library?.url else {
            return String()
        }
        url += "/osrf-gateway-v1?service="
        url.append(service)
        url.append("&method=")
        url += method
        
        for arg in args {
            url += "&param="
            url += API.gatewayParam(arg)
        }

        return url
    }
}
