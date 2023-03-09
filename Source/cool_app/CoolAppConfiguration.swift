//
//  AppConfiguration.swift
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

class CoolAppConfiguration: AppConfiguration {
    let title = "COOL"
    let url = "https://cool-cat.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    let sort: String? = nil
    let detailsExtraLinkText: String? = "Additional Content"
    let detailsExtraLinkQuery: String? = "expand=addedcontent;ac=summary"
    let detailsExtraLinkFragment: String? = "addedcontent"

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldShowExpiration = true
    let enableHoldPhoneNotification = true
    let enableHoldUseOverride = false
    let enablePartHolds = false
    let enableTitleHoldOnItemWithParts = false
    let enableMainSceneBottomToolbar = false
    let enablePayFines = false
    let enableHoursOfOperation = true
    let enableMessages = false
    let enableEventsButton = true
    let groupCopyInfoBySystem = false
    let enableCopyInfoWebLinks = true
    let needMARCRecord = false
    let showOnlineAccessHostname = true
    let alwaysUseActionSheetForOnlineLinks = false
    let haveColorButtonImages = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100
}
