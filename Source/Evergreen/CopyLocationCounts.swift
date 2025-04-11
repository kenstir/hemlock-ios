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

// Details of the copies in an org unit; location, call number, and status
class CopyLocationCounts {
    let orgID: Int
    let callNumberPrefix: String?
    let callNumberLabel: String?
    let callNumberSuffix: String?
    let shelvingLocation: String
    var countsByStatus: [(Int, Int)] = [] // (copyStatusID, count)
    var copyInfoHeading: String = "Unknown Location"
    var copyInfoSubheading: String = ""

    var callNumber: String {
        var ret = ""
        if let prefix = callNumberPrefix, !prefix.isEmpty {
            ret = ret + prefix + " "
        }
        if let label = callNumberLabel {
            ret = ret + label
        }
        if let suffix = callNumberSuffix, !suffix.isEmpty {
            ret = ret + " " + suffix
        }
        return ret
    }
    
    var countsByStatusLabel: String {
        var arr: [String] = []
        for (copyStatusID, copyCount) in self.countsByStatus {
            let copyStatus = CopyStatus.label(forID: copyStatusID)
            arr.append("\(copyCount) \(copyStatus)")
        }
        return arr.joined(separator: "\n")
    }
    
    init(orgID: Int, callNumberPrefix: String?, callNumberLabel: String?, callNumberSuffix: String?, location: String) {
        self.orgID = orgID
        self.callNumberPrefix = callNumberPrefix
        self.callNumberLabel = callNumberLabel
        self.callNumberSuffix = callNumberSuffix
        self.shelvingLocation = location
    }

    // The response to copyLocationCounts is unusual; it is not an OSRFObject
    // in wire protocol, it is a raw payload.
    static func makeArray(fromPayload payload: Any?) -> [CopyLocationCounts] {
        var copyLocationCounts: [CopyLocationCounts] = []
        guard let payloadItems = payload as? [Any],
            let items = payloadItems.first as? [Any] else
        {
            return copyLocationCounts
        }
        for elem in items {
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
                let copyLocationCount = CopyLocationCounts(orgID: orgID, callNumberPrefix: callNumberPrefix, callNumberLabel: callNumberLabel, callNumberSuffix: callNumberSuffix, location: copyLocation)
                copyLocationCounts.append(copyLocationCount)
                for (copyStatusIDString, copyCount) in countsByStatus {
                    if let copyStatusID = Int(copyStatusIDString) {
                        copyLocationCount.countsByStatus.append((copyStatusID, copyCount))
                        //print("\(copyStatusID) -> \(copyCount)")
                    }
                }
                if let org = Organization.find(byId: orgID) {
                    copyLocationCount.copyInfoHeading = org.name
                    copyLocationCount.copyInfoSubheading = ""
                    if App.config.groupCopyInfoBySystem,
                        let parentID = org.parent,
                        let parent = Organization.find(byId: parentID)
                    {
                        copyLocationCount.copyInfoHeading = parent.name
                        copyLocationCount.copyInfoSubheading = org.name
                    }
                }
            } else {
                //TODO: analytics
                print("failed to parse copyLocationCount \(elem)")
            }
        }
        
        return CopyLocationCounts.sortArray(copyLocationCounts)
    }
    
    private static func sortArray(_ array: [CopyLocationCounts]) -> [CopyLocationCounts] {
        var ret: [CopyLocationCounts] = []

        // if a branch is not opac visible, its copies should not be visible
        for elem in array {
            if let org = Organization.find(byId: elem.orgID),
               org.opacVisible
            {
                ret.append(elem)
            }
        }
        
//        print("--------------before sorting")
//        for elem in ret {
//            print("\(elem.copyInfoHeading)")
//            print("    \(elem.copyInfoSubheading)")
//        }

        if App.config.groupCopyInfoBySystem {
            // sort by system, then by branch, like http://gapines.org/eg/opac/record/5700567?locg=1
            ret.sort {
                guard let a = Organization.find(byId: $0.orgID),
                    let b = Organization.find(byId: $1.orgID) else { return true }

                if let aParent = a.parent,
                    let aParentOrg = Organization.find(byId: aParent),
                    let bParent = b.parent,
                    let bParentOrg = Organization.find(byId: bParent),
                    aParent != bParent
                {
                    return aParentOrg.name < bParentOrg.name
                }
                return a.name < b.name
            }
        } else {
            ret.sort {
                guard let a = Organization.find(byId: $0.orgID),
                    let b = Organization.find(byId: $1.orgID) else { return true }
                
                return a.name < b.name
            }
        }
        
//        print("--------------after sorting")
//        for elem in ret {
//            print("\(elem.copyInfoHeading)")
//            print("    \(elem.copyInfoSubheading)")
//        }

        return ret
    }
}
