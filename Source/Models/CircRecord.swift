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
    
    var title: String { return metabibRecord?.title ?? "Unknown Title" }
    var author: String { return metabibRecord?.author ?? "Unknown Author" }
    var format: String { return Format.getDisplayLabel(forSearchFormat: metabibRecord?.searchFormat) }
    var dueDate: String { return circObj?.getDateString("due_date") ?? "Unknown" }
    var renewalsRemaining: Int { return circObj?.getInt("renewal_remaining") ?? 0 }

    init(id: Int) {
        self.id = id
    }
}
