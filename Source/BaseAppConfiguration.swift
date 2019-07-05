//
//  BaseAppConfiguration.swift
//  Hemlock
//
//  Created by Kenneth Cox on 7/5/19.
//  Copyright © 2019 Ken Cox. All rights reserved.
//

import Foundation

class BaseAppConfiguration: AppConfiguration {
    var title: String
    var url: String
    var logSubsystem: String = Bundle.appIdentifier
    var bugReportEmailAddress: String
    var searchFormatsJSON: String
    var enableHierarchicalOrgTree = false
    var enableHoldShowQueuePosition = true
    var enableHoldPhoneNotification = false
    var enableMainSceneBottomToolbar = false
    var enablePayFines = false
    var groupCopyInfoBySystem = false
    var needMARCRecord = false
    var barcodeFormat = BarcodeFormat.Codabar
    var searchLimit = 100
    
    init(title: String, url: String, bugReportEmailAddress: String, searchFormatsJSON: String) {
        self.title = title
        self.url  = url
        self.bugReportEmailAddress = bugReportEmailAddress
        self.searchFormatsJSON = searchFormatsJSON
    }
    
    fileprivate func isOnlineFormat(searchFormat: String) -> Bool {
        if searchFormat == "picture" {
            return true
        }
        let label = Format.getDisplayLabel(forSearchFormat: searchFormat)
        return label.hasPrefix("E-")
    }
    
    func isOnlineResource(record: MBRecord) -> Bool {
        if let onlineLocation = record.onlineLocation,
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
        if let online_loc = record.onlineLocation {
            links.append(Link(href: online_loc, text: ""))
        }
        return links
    }
}
