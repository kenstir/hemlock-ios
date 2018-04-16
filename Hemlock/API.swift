//  API.swift
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

struct API {
    // endpoints
    static let directoryURL = "https://evergreen-ils.org/directory/libraries.json"

    // auth service
    static let auth = "open-ils.auth"
    static let authInit = "open-ils.auth.authenticate.init"
    static let authComplete = "open-ils.auth.authenticate.complete"
    static let authGetSession = "open-ils.auth.session.retrieve"

    static var library: Library?
    
    static func createRequest(service: String, method: String, args: [Any]) -> Alamofire.Request
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
