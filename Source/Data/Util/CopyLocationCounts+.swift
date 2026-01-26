//
//  Copyright (c) 2026 Kenneth H. Cox
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

struct CopyLocationLabel {
    let heading: String
    let subhead: String
}

extension CopyLocationCounts {
    var copyLocationLabel: CopyLocationLabel {
        var heading = ""
        var subhead = ""
        if let org = Organization.find(byID: orgID) {
            heading = org.name
            if App.config.groupCopyInfoBySystem,
                let parentID = org.parent,
                let parent = Organization.find(byID: parentID)
            {
                heading = parent.name
                subhead = org.name
            }
        }
        return CopyLocationLabel(heading: heading, subhead: subhead)
    }
}

/// sort and filter copy location counts for display
/// - Parameter array: array of CopyLocationCounts
/// - Returns: array filtered to visible orgs, sorted by org name or parent org name
func visibleCopyLocationCounts(from array: [CopyLocationCounts]) -> [CopyLocationCounts] {
    var ret: [CopyLocationCounts] = []
    let consortiumService = App.serviceConfig.consortiumService

    // if a branch is not opac visible, its copies should not be visible
    for elem in array {
        if let org = consortiumService.find(byID: elem.orgID),
           org.opacVisible
        {
            ret.append(elem)
        }
    }

    if App.config.groupCopyInfoBySystem {
        // sort by system, then by branch, like http://gapines.org/eg/opac/record/5700567?locg=1
        ret.sort {
            guard let a = consortiumService.find(byID: $0.orgID),
                let b = consortiumService.find(byID: $1.orgID) else { return true }

            if let aParent = a.parent,
                let aParentOrg = consortiumService.find(byID: aParent),
                let bParent = b.parent,
                let bParentOrg = consortiumService.find(byID: bParent),
                aParent != bParent
            {
                return aParentOrg.name < bParentOrg.name
            }
            return a.name < b.name
        }
    } else {
        ret.sort {
            guard let a = consortiumService.find(byID: $0.orgID),
                let b = consortiumService.find(byID: $1.orgID) else { return true }

            return a.name < b.name
        }
    }

    return ret
}
