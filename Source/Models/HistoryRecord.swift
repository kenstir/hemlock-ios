//
//  HistoryRecord.swift
//
//  Copyright (C) 2023 Kenneth H. Cox
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

/// A `HistoryRecord` is an item from the patron's circulation history
class HistoryRecord {

    let id: Int
    let auchObj: OSRFObject
    var metabibRecord: MBRecord?

    var title: String {
        if let title = metabibRecord?.title, !title.isEmpty { return title }
//        if let title = acpObj?.getString("dummy_title"), !title.isEmpty { return title }
        return "Unknown Title"
    }
    var author: String {
        if let author = metabibRecord?.author, !author.isEmpty { return author }
//        if let author = acpObj?.getString("dummy_author"), !author.isEmpty { return author }
        return ""
    }
    var format: String { return metabibRecord?.iconFormatLabel ?? "" }
    var dueDate: Date? { return auchObj.getDate("due_date") }
    var dueDateLabel: String { return auchObj.getDateLabel("due_date") ?? "Unknown" }
    var targetCopy: Int { return auchObj.getInt("target_copy") ?? -1 }

    init(id: Int, auchObj: OSRFObject, metabibRecord: MBRecord? = nil) {
        self.id = id
        self.auchObj = auchObj
        self.metabibRecord = metabibRecord
    }
}
