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

/* Emulate the behavior of OPAC messages customized in hold_error_messages.tt2.
 *
 * This class is not used directly; it loads the customizations from the app bundle
 * and injects them into the Event class.
 *
 * To customize a message by "fail_part", add it to res/raw/fail_part_msg_map.json
 */
class MessageMap {
    static var initialized = false
    static var failPartMessageMap: [String: String] = [:]
    
    static func loadFromResources() {
        guard
            let path = Bundle.main.path(forResource: "fail_part_msg_map", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let obj = try? JSONSerialization.jsonObject(with: data),
            let map = obj as? [String: String] else
        {
            return
        }
        failPartMessageMap = map
    }
}
