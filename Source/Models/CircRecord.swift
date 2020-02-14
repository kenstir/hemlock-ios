//
//  CircRecord.swift
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

/// A `CircRecord` is a record of an item in circulation
class CircRecord {
    
    let id: Int
    var circObj: OSRFObject?
    var metabibRecord: MBRecord?
    var acpObj: OSRFObject?
    
    var title: String {
        if let title = metabibRecord?.title { return title }
        if let title = acpObj?.getString("dummy_title") { return title }
        return "Unknown Title"
        
    }
    var author: String {
        if let author = metabibRecord?.author { return author }
        if let author = acpObj?.getString("dummy_author") { return author }
        return ""
    }
    var format: String { return metabibRecord?.iconFormatLabel ?? "" }
    var dueDate: Date? { return circObj?.getDate("due_date") }
    var dueDateLabel: String { return circObj?.getDateLabel("due_date") ?? "Unknown" }
    var renewalsRemaining: Int { return circObj?.getInt("renewal_remaining") ?? 0 }
    var targetCopy: Int { return circObj?.getInt("target_copy") ?? -1 }

    init(id: Int) {
        self.id = id
    }
}
