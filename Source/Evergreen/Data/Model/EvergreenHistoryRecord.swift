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

class EvergreenHistoryRecord: HistoryRecord {
    private let lock = NSRecursiveLock()

    let id: Int
    let auchObj: OSRFObject
    private(set) var record: BibRecord?

    var title: String {
        if let title = record?.title, !title.isEmpty { return title }
//        if let title = acpObj?.getString("dummy_title"), !title.isEmpty { return title }
        return "Unknown Title"
    }
    var author: String {
        if let author = record?.author, !author.isEmpty { return author }
//        if let author = acpObj?.getString("dummy_author"), !author.isEmpty { return author }
        return ""
    }
    var format: String { return record?.iconFormatLabel ?? "" }
    var dueDate: Date? { return auchObj.getDate("due_date") }
    var dueDateLabel: String { return auchObj.getDateLabel("due_date") ?? "Unknown" }
    var checkoutDate: Date? { return auchObj.getDate("xact_start") }
    var checkoutDateLabel: String { return auchObj.getDateLabel("xact_start") ?? "Unknown" }
    var returnedDate: Date? { return auchObj.getDate("checkin_time") }
    var returnedDateLabel: String { return auchObj.getDateLabel("checkin_time") ?? "Not Returned" }
    var targetCopy: Int { return auchObj.getInt("target_copy") ?? -1 }

    init(id: Int, obj: OSRFObject) {
        self.id = id
        self.auchObj = obj
        self.record = nil
    }

    /// mt-safe
    func setBibRecord(_ record: BibRecord?) {
        lock.lock(); defer { lock.unlock() }
        self.record = record
    }

    static func makeArray(_ objects: [OSRFObject]) -> [HistoryRecord] {
        var ret: [HistoryRecord] = []
        for obj in objects {
            if let id = obj.getInt("id") {
                ret.append(EvergreenHistoryRecord(id: id, obj: obj))
            }
        }
        return ret
    }
}
