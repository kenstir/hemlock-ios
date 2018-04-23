//
//  GatewayResponse.swift
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

enum GatewayError: Error {
    case malformedPayload(String)
    case failure(String)
}

enum GatewayResultType {
    case string
    case object
    case array
    case error
}

struct GatewayResponse {
    var type: GatewayResultType
    var error: GatewayError?
    var stringResult: String?
    var objectResult: [String: Any]?
    var arrayResult: [Any]?
    var failed: Bool {
        return type == .error
    }
    
    init() {
        type = .error
        error = .failure("unintialized")
    }
    
    init(_ jsonString: String) {
        self.init()
        guard let data = jsonString.data(using: .utf8) else {
            error = .failure("Unable to encode as utf8: \(jsonString)")
            return
        }
        self.init(data)
    }

    init(_ data: Data) {
        self.init()

        guard var json = decodeJSON(data) else {
            error = .failure("Response not JSON")
            return
        }
        debugPrint(json)

        guard let status = json["status"] as? Int else {
            error = .failure("Response missing status")
            return
        }
        if status != 200 {
            error = .failure("Response status \(status)")
            return
        }

        // payload is always an array,
        // usually an array of one json object,
        // but in the cases of authInit it is an array of one string
        guard let payload = json["payload"] as? [Any] else {
            error = .failure("Response missing payload")
            return
        }
        if let val = payload.first as? [String: Any] {
            type = .object
            objectResult = val
        } else if let val = payload.first as? [Any] {
            type = .array
            arrayResult = val
        } else if let val = payload.first as? String {
            type = .string
            stringResult = val
        } else {
            error = .failure("Response has unexpected payload: \(String(describing: payload))")
            return
        }
        error = nil
    }
    
    func decodeJSON(_ data: Data) -> [String: Any]? {
        if
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any]
        {
            return jsonObject
        } else {
            return nil
        }
    }

    static func makeError(_ reason: String) -> GatewayResponse {
        var resp = GatewayResponse()
        resp.error = .failure(reason)
        return resp
    }
    
    func getString(_ key: String) -> String? {
        if let val = objectResult?[key] as? String {
            return val
        }
        return stringResult
    }
    
    func getObject(_ key: String) -> Any? {
        if let val = objectResult?[key] {
            return val
        }
        return nil
    }
    
    // some queries return at times a list of String IDs and at times
    // a list of Int IDs; smooth that path
    func getListOfIDs(_ key: String) -> [Int] {
        var ret: [Int] = []
        if let listOfStrings = getObject(key) as? [String] {
            for str in listOfStrings {
                if let id = Int(str) {
                    ret.append(id)
                }
            }
        } else if let listOfInt = getObject(key) as? [Int] {
            ret = listOfInt
        }
        return ret
    }
}
