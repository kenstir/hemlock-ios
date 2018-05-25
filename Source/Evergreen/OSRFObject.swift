//
//  OSRFObject.swift
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

/// An `OSRFObject` represents the decoded Evergreen objects returned in a `GatewayResponse`
/// In practice this is just a [String:Any?] dictionary that is equatable.
struct OSRFObject: Equatable {
    
    var dict: [String: Any?]
    
    init(_ dict: [String: Any?] = [:]) {
        self.dict = dict
    }
    
    //MARK: - accessors
    
    func getString(_ key: String) -> String? {
        if let val = dict[key] as? String {
            return val
        }
        return nil
    }
    
    func getInt(_ key: String) -> Int? {
        if let val = dict[key] as? Int {
            return val
        }
        return nil
    }
    
    func getBool(_ key: String) -> Bool? {
        if let val = dict[key] as? Bool {
            return val
        }
        if let val = dict[key] as? String {
            if val == "t" {
                return true
            } else {
                return false
            }
        }
        return nil
    }
    
    func getAny(_ key: String) -> Any? {
        if let val = dict[key] {
            return val
        }
        return nil
    }
    
    // some queries return at times a list of String IDs and at times
    // a list of Int IDs; smooth that path
    func getListOfIDs(_ key: String) -> [Int] {
        var ret: [Int] = []
        if let listOfStrings = dict[key] as? [String] {
            for str in listOfStrings {
                if let id = Int(str) {
                    ret.append(id)
                }
            }
        } else if let listOfInt = getAny(key) as? [Int] {
            ret = listOfInt
        }
        return ret
    }

    // MARK: - Equatable

    // It seems like there should be an easier way to implement this
    // but this is just for unit tests.  So we treat two OSRFObjects
    // as equal if they serialize to the same JSON String.
    static func == (lhs: OSRFObject, rhs: OSRFObject) -> Bool {
        
        if lhs.dict.count != rhs.dict.count {
            return false
        }
        if lhs.dict.keys != rhs.dict.keys {
            return false
        }
        if
            let jsonDataLHS = try? JSONSerialization.data(withJSONObject: lhs.dict),
            let strLHS = String(data: jsonDataLHS, encoding: .utf8),
            let jsonDataRHS = try? JSONSerialization.data(withJSONObject: rhs.dict),
            let strRHS = String(data: jsonDataRHS, encoding: .utf8) {
            return strLHS == strRHS
        }
        return false
    }
}
