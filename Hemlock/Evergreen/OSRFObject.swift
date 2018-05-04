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

struct OSRFObject: Equatable {
    
    var dict: [String: Any?]
    
    init(_ dict: [String: Any?] = [:]) {
        self.dict = dict
    }

    // MARK: Equatable
    // It seems like there should be an easier way to implement this
    // but this is just for unit tests.  So we treat two OSRFObjects
    // as equal if they serialize to the same JSON String.
    static func == (lhs: OSRFObject, rhs: OSRFObject) -> Bool {
        
        if lhs.dict.count != rhs.dict.count {
            return false
        }
        let keys = lhs.dict.keys
        if keys != rhs.dict.keys {
            return false
        }
        for key in keys {
            print("key \(key):")
            if lhs.dict[key] == nil {
                print("    lhs nil")
                if rhs.dict[key] == nil {
                    print("    rhs nil")
                    continue
                }
                return false
            }
            guard let v1 = lhs.dict[key],
                let v2 = rhs.dict[key] else
            {
                print("    *** unable to unwrap")
                return false
            }
            let t1 = type(of: v1)
            let t2 = type(of: v2)
            if v1 == nil {
                print("    lhs nil")
                if v2 == nil {
                    print("    rhs nil")
                    continue
                }
//                return false
            }
            print("    lhs '\(v1!)' type '\(t1)'")
            print("    rhs '\(v2!)' type '\(t2)'")
//            if isEqual(type: t1, a: v1, b: v2) {
//                print("     lhs == rhs")
//            } else {
//                return false
//            }
        }
        debugPrint("lhs", lhs)
        debugPrint("rhs", rhs)
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
