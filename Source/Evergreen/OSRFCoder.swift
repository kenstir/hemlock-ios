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
    
    static func decode(_ netClass: String, wireString: String) throws -> OSRFObject {
        guard
            let data = wireString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let arr = json as? [Any?],
            let coder = registry[netClass] else
        {
            throw OSRFDecodingError.jsonDecodingFailed
        }
        debugPrint(json)
        
        var dict: [String: Any?] = [:]
        let fields = coder.fields
        for i in 0...arr.count-1 {
            let key = fields[i]
            let val = arr[i]
            dict[key] = val
            print("field at index \(i) is \(key) => \(String(describing: val))")
        }
        
        return OSRFObject(dict)
    }
}
