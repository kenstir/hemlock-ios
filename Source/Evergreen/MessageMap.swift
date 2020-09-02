//
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

/* Manage strings that can be customized per-app
 *
 * failPartMessageMap -
 *     emulates the behavior of OPAC messages customized in hold_error_messages.tt2.
 *     Used by GatewayResponse.  To customize a message by "fail_part", add it to
 *     fail_part_msg_map.json
 *
 * string - any other customized string, ala R.string.x on Android
 */
typealias R = MessageMap
class MessageMap {
    static var initialized = false
    static var failPartMessageMap: [String: String] = [:]
    static var string: [String: String] = [:]
    
    static func loadFromResources() {
        guard !initialized else { return }
        loadFailPartMessageMap()
        loadStrings()
        initialized = true
    }
    
    // return custom string if any, else return parameter
    static func getString(_ str: String) -> String {
        if let customString = string[str] {
            return customString
        }
        return str
    }

    static private func loadFailPartMessageMap() {
        if let map = loadStringMap(forResource: "fail_part_msg_map") {
            failPartMessageMap.merge(map) { (_, new) in new }
        }
    }

    // Merge strings.json with custom_strings.json, if any.
    // This behaves in practice like strings.xml merging in Android.
    static private func loadStrings() {
        if let map = loadStringMap(forResource: "strings") {
            string.merge(map) { (_, new) in new }
        }
        if let map = loadStringMap(forResource: "custom_strings") {
            string.merge(map) { (_, new) in new }
        }
    }

    static private func loadStringMap(forResource resource: String) -> [String: String]? {
        guard
            let path = Bundle.main.path(forResource: resource, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let obj = try? JSONSerialization.jsonObject(with: data),
            let map = obj as? [String: String] else
        {
            return nil
        }
        return map
    }
}
