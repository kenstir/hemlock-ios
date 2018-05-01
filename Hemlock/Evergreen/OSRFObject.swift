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
    
    var payload: [String: Any?]
    
    init(_ payload: [String: Any?] = [:]) {
        self.payload = payload
    }

    // MARK: Equatable
    // It seems like there should be an easier way to implement this
    // but this is just for unit tests.  So we treat two OSRFObjects
    // as equal if they serialize to the same JSON String.
    static func == (lhs: OSRFObject, rhs: OSRFObject) -> Bool {
        if lhs.payload.count != rhs.payload.count {
            return false
        }
        let keys = lhs.payload.keys
        if keys != rhs.payload.keys {
            return false
        }
        if
            let jsonDataLHS = try? JSONSerialization.data(withJSONObject: lhs),
            let strLHS = String(data: jsonDataLHS, encoding: .utf8),
            let jsonDataRHS = try? JSONSerialization.data(withJSONObject: rhs),
            let strRHS = String(data: jsonDataRHS, encoding: .utf8) {
            return strLHS == strRHS
        }
        return false
    }
}
