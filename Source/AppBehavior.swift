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
    func getCustomString(_ key: String) -> String?
}

class BaseAppBehavior: AppBehavior {
    var customStrings: [String: String] = [:]
    
    fileprivate func isOnlineFormat(iconFormatLabel: String?) -> Bool {
        guard let label = iconFormatLabel else { return false }
        if label == "Picture" {
            return true
        }
        return label.hasPrefix("E-")
    }
    
    func isOnlineResource(record: MBRecord) -> Bool {
        if let item_form = record.attrs?["item_form"] {
            if item_form == "o" || item_form == "s" {
                return true
            }
        }
        
        return isOnlineFormat(iconFormatLabel: record.iconFormatLabel);
    }
    
    func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        if let online_loc = record.firstOnlineLocationInMVR {
            links.append(Link(href: online_loc, text: ""))
        }
        return links
    }
    
    func getCustomString(_ key: String) -> String? {
        return customStrings[key]
    }
}
