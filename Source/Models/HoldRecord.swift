//
//  HoldRecord.swift
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

class HoldRecord {
    
    //MARK: - Properties

    var ahrObj: OSRFObject
    var mvrObj: OSRFObject?
    var qstatsObj: OSRFObject?
    
    var target: Int? { return ahrObj.getID("target") }
    var holdType: String? { return ahrObj.getString("hold_type") }
    var title: String { return mvrObj?.getString("title") ?? "Unknown" }
    var author: String { return mvrObj?.getString("author") ?? "Unknown" }
    var queuePosition: Int { return qstatsObj?.getInt("queue_position") ?? 0 }
    var totalHolds: Int { return qstatsObj?.getInt("total_holds") ?? 0 }
    var potentialCopies: Int { return qstatsObj?.getInt("potential_copies") ?? 0 }
    var status: String {
        let s = qstatsObj?.getInt("status") ?? -1
        if s == 4 { return "Available" }
        else if s == 7 { return "Suspended" }
        else if s == 3 || s == 8 { return "In transit" }
        else if s < 3 { return "Waiting for copy" }
        else { return "" }
    }

    //MARK: - Functions
    
    init(obj: OSRFObject) {
        self.ahrObj = obj
    }
    
    static func makeArray(_ objects: [OSRFObject]) -> [HoldRecord] {
        var ret: [HoldRecord] = []
        for obj in objects {
            ret.append(HoldRecord(obj: obj))
        }
        return ret
    }
}
