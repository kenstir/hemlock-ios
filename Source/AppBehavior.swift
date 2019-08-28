//
//  AppBehavior.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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

protocol AppBehavior {
    func isOnlineResource(record: MBRecord) -> Bool
    func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link]
    func getString(_ key: String) -> String?
}

class BaseAppBehavior: AppBehavior {
    var customStrings: [String: String] = [:]
    
    fileprivate func isOnlineFormat(searchFormat: String) -> Bool {
        if searchFormat == "picture" {
            return true
        }
        let label = Format.getDisplayLabel(forSearchFormat: searchFormat)
        return label.hasPrefix("E-")
    }
    
    func isOnlineResource(record: MBRecord) -> Bool {
        if let onlineLocation = record.firstOnlineLocationInMVR,
            !onlineLocation.isEmpty,
            let searchFormat = record.searchFormat,
            isOnlineFormat(searchFormat: searchFormat)
        {
            return true
        }
        return false
    }
    
    func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        if let online_loc = record.firstOnlineLocationInMVR {
            links.append(Link(href: online_loc, text: ""))
        }
        return links
    }
    
    func getString(_ key: String) -> String? {
        return customStrings[key]
    }
}
