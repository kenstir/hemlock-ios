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
    var mvrObj: OSRFObject?
    
    var title: String { return mvrObj?.getString("title") ?? "Unknown" }
    var author: String { return mvrObj?.getString("author") ?? "Unknown" }
    var dueDate: String { return circObj?.getDateString("due_date") ?? "Unknown" }

    init(id: Int) {
        self.id = id
    }
}
