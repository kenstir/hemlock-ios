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

class EvergreenOrgClosure: OrgClosure {
    let start: Date
    let end: Date
    let reason: String
    let obj: OSRFObject

    init(start: Date, end: Date, reason: String, obj: OSRFObject) {
        self.start = start
        self.end = end
        self.reason = reason
        self.obj = obj
    }

    func toInfo() -> OrgClosureInfo {
        let startDateString = OSRFObject.outputDayOnlyFormatter.string(from: start)
        let isFullDay = obj.getBoolOrFalse("full_day")
        let isMultiDay = obj.getBoolOrFalse("multi_day")
        var isDateRange = false
        var dateString = startDateString
        if isMultiDay {
            isDateRange = true
            let endDateString = OSRFObject.outputDayOnlyFormatter.string(from: end)
            dateString = "\(startDateString) - \(endDateString)"
        } else if isFullDay {
            dateString = startDateString
        } else {
            isDateRange = true
            let startDateTimeString = OSRFObject.getDateTimeLabel(from: start)
            let endDateTimeString = OSRFObject.getDateTimeLabel(from: end)
            dateString = "\(startDateTimeString) - \(endDateTimeString)"
        }
        return OrgClosureInfo(dateString: dateString, reason: reason, isDateRange: isDateRange)
    }

    static func makeArray(_ array: [OSRFObject]) -> [EvergreenOrgClosure] {
        let now = Date()
        var closures: [EvergreenOrgClosure] = []
        for obj in array {
            if let start = obj.getDate("close_start"),
               let end = obj.getDate("close_end"),
               end > now
            {
                let reason = obj.getString("reason") ?? "No reason provided"
                closures.append(EvergreenOrgClosure(start: start, end: end, reason: reason, obj: obj))
            }
        }
        return closures
    }
}
