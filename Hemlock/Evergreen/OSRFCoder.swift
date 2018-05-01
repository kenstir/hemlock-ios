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

/// `OSRFCoder` encodes and decodes OSRF objects to and from OSRF wire format.
///
/// An `OSRFObject` is whatever gets returned in the top-level "payload" field
/// of a GatewayResponse
/// On the wire, OSRFObjects may be a straight JSON object or array, or it
/// may be an encoded , with fields, but on the
struct OSRFCoder {
    static private var registry: [String: OSRFCoder] = [:]
    
    var fields: [String]
    var netClass: String
    
    init(netClass: String, fields: [String]) {
        self.netClass = netClass
        self.fields = fields
    }
    
    static func clear() -> Void {
        registry.removeAll()
    }
    
    static func registerClass(_ netClass: String, fields: [String]) -> Void {
        let registeredObject = OSRFCoder(netClass: netClass, fields: fields)
        registry[netClass] = registeredObject
    }
    
    static func findClass(_ netClass: String) -> OSRFCoder? {
        let registeredObject = registry[netClass]
        return registeredObject
    }
    
    static func decode(_ netClass: String, wireString: String) -> OSRFObject? {
        guard
            let coder = registry[netClass],
            let data = wireString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonArray = json as? [Any?] else
        {
            return nil
        }
        return OSRFObject(["children": nil, "id": 11])
    }
}
