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

/// `Gateway` represents the endpoint or catalog OSRF server.
class Gateway {

    //MARK: - fields

    /// the URL of the JSON directory of library systems available for use in the Hemlock app
    static let directoryURL = "https://evergreen-ils.org/directory/libraries.json"

    /// the selected library system
    static var library: Library?

    /// an encoding that serializes parameters as param=1&param=2
    static let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)
    
    //MARK: - static methods
    
    /// create an Alamofire request for calling the gateway
    static func makeRequest(service: String, method: String, args: [Any]) -> Alamofire.DataRequest
    {
        let url = gatewayURL()
        let parameters: [String: Any] = ["service": service, "method": method, "param": gatewayParams(args)]
        let request = Alamofire.request(url, method: .post, parameters: parameters, encoding: gatewayEncoding)
        return request
    }
    
    /// encode params as needed by the gateway
    static func gatewayParams(_ args: [Any]) -> [String]
    {
        var params: [String] = []
        for arg in args {
            if arg is String {
                params.append("\"\(arg)\"")
            } else if arg is Double || arg is Int {
                params.append("\(arg)")
            } else if let dict = arg as? [String: Any],
                let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                let str = String(data: jsonData, encoding: .utf8)
            {
                params.append(str)
            } else {
                params.append("???")
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
    
    static func idlURL() -> URL? {
        var url = library?.url ?? ""
        url += "/reports/fm_IDL.xml?"
        var params: [String] = []
        for netClass in API.netClasses.split(separator: ",") {
            params.append("class=" + netClass)
        }
        url += params.joined(separator: "&")
        return URL(string: url)
    }
}
