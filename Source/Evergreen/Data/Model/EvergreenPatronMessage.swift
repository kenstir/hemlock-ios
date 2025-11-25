//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import Foundation

class EvergreenPatronMessage: PatronMessage {
    let id: Int
    let obj: OSRFObject
    
    var createDate: Date? {
        return obj.getDate("create_date")
    }
    var createDateLabel: String? {
        return obj.getDateLabel("create_date")
    }
    var isRead: Bool {
        return obj.getDate("read_date") != nil
    }
    var isDeleted: Bool {
        return obj.getBoolOrFalse("deleted")
    }
    var isPatronVisible: Bool {
        return obj.getBoolOrFalse("pub")
    }
    var title: String {
        return obj.getString("title") ?? ""
    }
    var message: String {
        return obj.getString("message") ?? ""
    }

    init(id: Int, obj: OSRFObject) {
        self.id = id
        self.obj = obj
    }

    static func makeArray(_ objects: [OSRFObject]) -> [PatronMessage] {
        var ret: [PatronMessage] = []
        for obj in objects {
            if let id = obj.getInt("id") {
                ret.append(EvergreenPatronMessage(id: id, obj: obj))
            }
        }
        return ret
    }
}
