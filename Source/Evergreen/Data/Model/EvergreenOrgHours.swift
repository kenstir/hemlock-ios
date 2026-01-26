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

struct EvergreenOrgHours: OrgHours {
    var day0Hours: String? { return hours(forDay: 0) }
    var day1Hours: String? { return hours(forDay: 1) }
    var day2Hours: String? { return hours(forDay: 2) }
    var day3Hours: String? { return hours(forDay: 3) }
    var day4Hours: String? { return hours(forDay: 4) }
    var day5Hours: String? { return hours(forDay: 5) }
    var day6Hours: String? { return hours(forDay: 6) }

    var day0Note: String? { return obj?.getString("dow_0_note") }
    var day1Note: String? { return obj?.getString("dow_1_note") }
    var day2Note: String? { return obj?.getString("dow_2_note") }
    var day3Note: String? { return obj?.getString("dow_3_note") }
    var day4Note: String? { return obj?.getString("dow_4_note") }
    var day5Note: String? { return obj?.getString("dow_5_note") }
    var day6Note: String? { return obj?.getString("dow_6_note") }

    private var obj: OSRFObject?

    init(obj: OSRFObject?) {
        self.obj = obj
    }

    private func hours(forDay day: Int) -> String? {
        guard let openApiStr = obj?.getString("dow_\(day)_open"),
              let closeApiStr = obj?.getString("dow_\(day)_close") else { return nil }
        if openApiStr == closeApiStr {
            return "closed"
        }
        if let openDate = OSRFObject.apiHoursFormatter.date(from: openApiStr),
           let closeDate = OSRFObject.apiHoursFormatter.date(from: closeApiStr)
        {
            let openStr = OSRFObject.outputHoursFormatter.string(from: openDate)
            let closeStr = OSRFObject.outputHoursFormatter.string(from: closeDate)
            return "\(openStr) - \(closeStr)"
        }
        return nil
    }

    static func make(_ obj: OSRFObject?) -> EvergreenOrgHours? {
        guard let obj = obj else { return nil }
        return EvergreenOrgHours(obj: obj)
    }

}
