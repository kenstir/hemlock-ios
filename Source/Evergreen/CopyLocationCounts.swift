//
//  CopyLocationCounts.swift
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

class CopyLocationCounts {
    let org_id: Int
    let call_number_prefix: String?
    let call_number_label: String?
    let call_number_suffix: String?
    let copy_location: String
    var countsByCopyStatus: [(Int, Int)] = [] // array of (copyStatusID,count)
    
    init(org_id: Int, call_number_prefix: String?, call_number_label: String?, call_number_suffix: String?, copy_location: String) {
        self.org_id = org_id
        self.call_number_prefix = call_number_prefix
        self.call_number_label = call_number_label
        self.call_number_suffix = call_number_suffix
        self.copy_location = copy_location
    }

    static func makeArray(fromArray objects: [OSRFObject]) -> [CopyCounts] {
        var copyCounts: [CopyCounts] = []
        for obj in objects {
            if let orgID = obj.getInt("org_unit"),
                let available = obj.getInt("available"),
                let count = obj.getInt("count")
            {
                copyCounts.append(CopyCounts(orgID: orgID, count: count, available: available))
            }
        }
        return copyCounts
    }
}
