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

struct GatewayResponse {
    let status: Int
    let payloadString: String?
    let payloadObject: [String: Any]?
    let error: GatewayError?
    var failed: Bool {
        return error != nil
    }

    init(_ json: [String: Any]) {
        // refactor after green?
        var status = -1
        var payloadString: String?
        var payloadObject: [String: Any]?
        var error: GatewayError?

        // status must be an Int
        if let val = json["status"] as? Int {
            status = val
        }

        // payload is always an array,
        // usually an array of one json object,
        // but sometimes is an array of one string
        if let val = json["payload"] as? [Any] {
            if let obj = val.first as? [String: Any] {
                payloadObject = obj
            } else if let str = val.first as? String {
                payloadString = str
            } else if let arr = val.first as? [Any] {
                if arr.count == 0 {
                    payloadObject = [:]
                }
            }
        }
        
        // error checking
        if status == -1 {
            error = GatewayError.missing("status")
        } else if payloadObject == nil && payloadString == nil {
            error = GatewayError.unexpectedPayload
        }

        self.status = status
        self.payloadString = payloadString
        self.payloadObject = payloadObject
        self.error = error
    }
    
    func getString(_ key: String) -> String? {
        if let val = payloadObject?[key] as? String {
            return val
        }
        return payloadString
    }
    
    func getObject(_ key: String) -> Any? {
        if let val = payloadObject?[key] {
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
