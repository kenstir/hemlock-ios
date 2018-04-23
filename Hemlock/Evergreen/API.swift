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

    // todo: does this belong in GatewayRequest?
    static var library: Library?
    
    // an encoding that serializes parameters as param=1&param=2
    static let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)

    // todo: factor request handling out into GatewayRequest
    static func createRequest(service: String, method: String, args: [Any]) -> Alamofire.DataRequest
    {
        let url = API.gatewayURL()
        let parameters: [String: Any] = ["service": service, "method": method, "param": API.gatewayParams(args)]
        let request = Alamofire.request(url, method: .post, parameters: parameters, encoding: gatewayEncoding)
        return request
    }
    
    static func gatewayParams(_ args: [Any]) -> [String]
    {
        var params: [String] = []
        for arg in args {
            if arg is String {
                params.append("\"\(arg)\"")
            } else if arg is Double {
                params.append("\(arg)")
            } else if arg is Int {
                params.append("\(arg)")
            } else {
                params.append("*unexpectedType*")
            }
        }
        return params
    }
    
    static func gatewayURL() -> String
    {
        var url = library?.url ?? ""
        url += "/osrf-gateway-v1"
        return url
    }
}
