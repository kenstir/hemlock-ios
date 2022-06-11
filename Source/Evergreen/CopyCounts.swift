/*
 * Copyright (C) 2018 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */
import Foundation

// Summary of the available/total copies in an org unit
class CopyCounts {

    let orgID: Int
    let available: Int
    let count: Int
    //let depth: Int
    //let unshadow: Int
    //let transcendant: ???
    
    init(orgID: Int, count: Int, available: Int) {
        self.orgID = orgID
        self.count = count
        self.available = available
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
