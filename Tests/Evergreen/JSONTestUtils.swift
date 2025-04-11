//
//  Copyright (C) 2025 Kenneth H. Cox
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

import XCTest
import Foundation
@testable import Hemlock

class JSONTestUtils {

    static func parseArray(fromJSONStr jsonString: String) -> [Any?]? {
        if let data = jsonString.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data),
           let array = obj as? [Any?] {
            return array
        } else {
            return nil
        }
    }

    static func parseObjectArray(fromJSONStr jsonString: String) -> [JSONDictionary]? {
        if let data = jsonString.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data),
           let array = obj as? [JSONDictionary] {
            return array
        } else {
            return nil
        }
    }

    static func serializeObject(_ obj: Any) -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}
