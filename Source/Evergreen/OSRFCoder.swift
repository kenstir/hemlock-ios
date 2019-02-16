//
//  OSRFCoder.swift
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

enum OSRFDecodingError: Error {
    case classNotFound(String)
    case jsonDecodingFailed
    case unexpectedError(String)
}

/// `OSRFCoder` decodes OSRF objects from OSRF wire format.
/// For now, I don't need encoding.
struct OSRFCoder {
    static private var registry: [String: OSRFCoder] = [:]
    
    var netClass: String
    var fields: [String]
    
    init(netClass: String, fields: [String]) {
        self.netClass = netClass
        self.fields = fields
    }
    
    static func clearRegistry() -> Void {
        registry.removeAll()
    }
    
    static func registryCount() -> Int {
        return registry.count
    }
    
    static func registerClass(_ netClass: String, fields: [String]) -> Void {
        let registeredObject = OSRFCoder(netClass: netClass, fields: fields)
        registry[netClass] = registeredObject
    }
    
    static func findClass(_ netClass: String) -> OSRFCoder? {
        let registeredObject = registry[netClass]
        return registeredObject
    }
    
    /// decode an OSRFObject from wire protocol
    static func decode(fromDictionary dict: JSONDictionary) throws -> OSRFObject {
        var dictToDecode: JSONDictionary

        if let netClass = dict["__c"] as? String,
            let payload = dict["__p"] as? [Any?]
        {
            let obj = try decode(netClass, wirePayload: payload)
            dictToDecode = obj.dict
        } else {
            dictToDecode = dict
        }

        var ret: JSONDictionary = [:]
        for (k,v) in dictToDecode {
            if let vDictionary = v as? JSONDictionary {
                ret[k] = try decode(fromDictionary: vDictionary)
            } else if let vArray = v as? [JSONDictionary] {
                ret[k] = try decode(fromArray: vArray)
            } else {
                ret[k] = v
            }
        }
        return OSRFObject(ret)
    }
    
    /// decode an array of OSRFObjects from wire protocol
    static func decode(fromArray array: [JSONDictionary]) throws -> [OSRFObject] {
        var ret: [OSRFObject] = []
        for elem in array {
            try ret.append(decode(fromDictionary: elem))
        }
        return ret
    }

    /// decode an OSRFObject from a payload array in wire protocol
    static func decode(_ netClass: String, wirePayload jsonArray: [Any?]) throws -> OSRFObject {
        guard let coder = registry[netClass] else {
            throw OSRFDecodingError.classNotFound(netClass)
        }
        var dict: [String: Any?] = [:]
        let count = min(jsonArray.count, coder.fields.count)
        /*
        if jsonArray.count != coder.fields.count {
            print("kcxxx: class \(netClass) jsonArray.count \(jsonArray.count) coder.fields.count \(coder.fields.count)")
            if jsonArray.count > coder.fields.count {
                for i in coder.fields.count..<jsonArray.count {
                    print("kcxxx:     jsonExtraValue \(jsonArray[i])")
                }
            }
            if coder.fields.count > jsonArray.count && netClass != "aout" {
                for i in jsonArray.count..<coder.fields.count {
                    print("kcxxx:     coderMissingField \(coder.fields[i])")
                }
            }
        }
        */
        for i in 0..<count {
            let key = coder.fields[i]
            let val = jsonArray[i]
            dict[key] = val
        }
        
        return OSRFObject(dict)
    }
}
