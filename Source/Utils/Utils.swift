/*
 * Utils.swift
 *
 * Copyright (C) 2019 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import Foundation
import os.log

class Utils {
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Utils")

    static func coalesce<T>(_ values: T?...) -> T? {
        for value in values {
            if value != nil {
                return value
            }
        }
        return nil
    }

    // coalesce for Strings returns first non-nil non-empty string
    static func coalesce(_ values: String?...) -> String? {
        for value in values {
            if let val = value, !val.isEmpty {
                return val
            }
        }
        return nil
    }

    static func dump(dict: JSONDictionary) {
        for i in dict.keys.sorted() {
            if let val = dict[i], let v = val {
                print("  \(i) -> \(v)")
            } else {
                print("  \(i) -> nil")
            }
        }
    }
    
    static func toString(_ val: Bool?) -> String {
        if let v = val {
            return v ? "true" : "false"
        }
        return "nil"
    }
    
    // Given a pubdate like "2000", "c2002", "[2003]", or "2007-2014",
    // extract the first number as an Int for sorting.
    static func pubdateSortKey(_ pubdate: String?) -> Int? {
        if let s = pubdate,
           let startIndex = s.firstIndex(where: { $0.isNumber }) {
            let s2 = s[startIndex...]
            if let endIndex = s2.firstIndex(where: { !$0.isNumber}) {
                let s3 = s2[s2.startIndex..<endIndex]
                return Int(s3)
            } else {
                return Int(s2)
            }
        }
        return nil
    }
    
    // Given a title, return a sort key
    static func titleSortKey(_ title: String?) -> String {
        guard let t = title else { return "" }

        // uppercase and remove leading articles
        let t2 = t.uppercased()
            .removePrefix("A ")
            .removePrefix("AN ")
            .removePrefix("THE ")

        // filter out punctuation
        // modeled afterr code in misc_util.tt2 block get_marc_attrs
        return t2.replace(regex: "^[^A-Z0-9]*", with: "")
    }

    /// return an index that won't result in a crash for Index out of range
    static func safeIndex(_ index: Int, count: Int) -> Int {
        if index >= 0 && index < count {
            return index
        }
        //TODO: add analytics; this should not happen
        return 0
    }

}
