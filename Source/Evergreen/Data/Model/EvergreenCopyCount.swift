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

class EvergreenCopyCount: CopyCount {
    let orgID: Int
    let available: Int
    let count: Int

    init(orgID: Int, count: Int, available: Int) {
        self.orgID = orgID
        self.count = count
        self.available = available
    }
    
    static func makeArray(fromArray objects: [OSRFObject]) -> [CopyCount] {
        var copyCounts: [CopyCount] = []
        for obj in objects {
            if let orgID = obj.getInt("org_unit"),
                let available = obj.getInt("available"),
                let count = obj.getInt("count")
            {
                copyCounts.append(EvergreenCopyCount(orgID: orgID, count: count, available: available))
            }
        }
        return copyCounts
    }
}
