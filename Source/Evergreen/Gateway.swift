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

    static let log = OSLog(subsystem: App.config.logSubsystem, category: "Gateway")

    /// an encoding that serializes parameters as param=1&param=2
    static let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)
    
    //MARK: - static methods
    
    /// create an Alamofire request for calling the gateway
    static func makeRequest(service: String, method: String, args: [Any]) -> Alamofire.DataRequest
    {
        let url = gatewayURL()
        let parameters: [String: Any] = ["service": service, "method": method, "param": gatewayParams(args)]
        let request = Alamofire.request(url, method: .post, parameters: parameters, encoding: gatewayEncoding)
        os_log("req.params: %@", log: log, type: .info, parameters)
        return request
    }
    
    /// encode params as needed by the gateway
    static func gatewayParams(_ args: [Any]) -> [String]
    {
        var params: [String] = []
        for arg in args {
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
            } else if let jsonData = try? JSONSerialization.data(withJSONObject: arg),
                let str = String(data: jsonData, encoding: .utf8)
            {
                params.append(str)
            } else {
                debugPrint(arg)
                fatalError("unhandled arg type, arg = \(arg)")
            }
        }
        return params
    }
    
    static func gatewayURL() -> String
    {
        var url = App.library?.url ?? ""
        url += "/osrf-gateway-v1"
        return url
    }
    
    static func idlURL() -> String {
        var url = App.library?.url ?? ""
        url += "/reports/fm_IDL.xml?"
        var params: [String] = []
        for netClass in API.netClasses.split(separator: ",") {
            params.append("class=" + netClass)
        }
        url += params.joined(separator: "&")
        return url
    }
}
