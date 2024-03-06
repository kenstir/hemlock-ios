//
//  JSONUtils.swift
//  Copyright (C) 2020 Kenneth H. Cox
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

// NOTES about handling null in JSON
//
// Here we use 'as? JSONDictionary' aka '[String: Any?]' because
// that is necessary to handle null values like {"a":null}.  If
// we insteead used [String:Any] then we would get the NSNull object, not nil.
//
// But subscripting a JSONDictionary can be awkward, because in this code
// the type of 'val' is 'Any??':
//
//    let obj = parseObject(fromData: data)
//    let val = obj["a"]
//
// So for this reason we have getStr.
class JSONUtils {
    static func parseObject(fromStr str: String) -> JSONDictionary? {
        if let data = str.data(using: .utf8) {
            return parseObject(fromData: data)
        }
        return nil
    }

    static func parseObject(fromData data: Data) -> JSONDictionary? {
        if
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? JSONDictionary
        {
            return jsonObject
        } else {
            return nil
        }
    }

    static func getString(_ dict: JSONDictionary, key: String) -> String? {
        if let val = dict[key] as? String {
            return val
        }
        return nil
    }
}
