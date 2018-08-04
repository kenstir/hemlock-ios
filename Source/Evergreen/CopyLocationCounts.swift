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
    let orgID: Int
    let callNumberPrefix: String?
    let callNumberLabel: String?
    let callNumberSuffix: String?
    let location: String
    var countsByStatus: [(Int, Int)] = [] // (copyStatusID, count)
    
    init(orgID: Int, callNumberPrefix: String?, callNumberLabel: String?, callNumberSuffix: String?, location: String) {
        self.orgID = orgID
        self.callNumberPrefix = callNumberPrefix
        self.callNumberLabel = callNumberLabel
        self.callNumberSuffix = callNumberSuffix
        self.location = location
    }

    // The response to copyLocationCounts is a black sheep; it is not an OSRFObject
    // in wire protocol, it is a raw payload.
    static func makeArray(fromPayload payload: Any) -> [CopyLocationCounts] {
        var copyLocationCounts: [CopyLocationCounts] = []
        guard let payloadItems = payload as? [Any],
            let array = payloadItems.first as? [Any] else
        {
            return copyLocationCounts
        }
        for elem in array {
            debugPrint(elem)
            if let a = elem as? [Any],
                a.count == 6,
                let orgIDString = a[0] as? String,
                let orgID = Int(orgIDString),
                let callNumberPrefix = a[1] as? String,
                let callNumberLabel = a[2] as? String,
                let callNumberSuffix = a[3] as? String,
                let copyLocation = a[4] as? String,
                let countsByStatus = a[5] as? [String: Int]
            {
                debugPrint(countsByStatus)
                let copyLocationCount = CopyLocationCounts(orgID: orgID, callNumberPrefix: callNumberPrefix, callNumberLabel: callNumberLabel, callNumberSuffix: callNumberSuffix, location: copyLocation)
                copyLocationCounts.append(copyLocationCount)
                for (copyStatusIDString, copyCount) in countsByStatus {
                    if let copyStatusID = Int(copyStatusIDString) {
                        copyLocationCount.countsByStatus.append((copyStatusID, copyCount))
                        print("\(copyStatusID) -> \(copyCount)")
                    }
                }
            }
        }
        return copyLocationCounts
    }
}
