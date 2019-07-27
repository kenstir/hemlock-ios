//
//  BaseAppConfiguration.swift
//  Hemlock
//
//  Created by Kenneth Cox on 7/5/19.
//  Copyright © 2019 Ken Cox. All rights reserved.
//

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
