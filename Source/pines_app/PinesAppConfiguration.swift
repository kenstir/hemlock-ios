//
//  PinesAppConfiguration.swift
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

class PinesAppConfiguration: AppConfiguration {
    var title = "PINES"
    let url = "https://gapines.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    let sort: String? = nil
    let detailsExtraLinkText: String? = "More Information"
    let detailsExtraLinkQuery: String? = nil
    let detailsExtraLinkFragment: String? = "awards"

    let enableCheckoutHistory = true
    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = false
    let enableHoldShowExpiration = false
    let enableHoldPhoneNotification = true
    let enableHoldUseOverride = false
    let enablePartHolds = true
    let enableTitleHoldOnItemWithParts = true
    let enableMainSceneBottomToolbar = true
    let enablePayFines = true
    let enableHoursOfOperation = true
    let enableMessages = true
    let enableEventsButton = false
    let groupCopyInfoBySystem = true
    let enableCopyInfoWebLinks = true
    let needMARCRecord = true
    let showOnlineAccessHostname = true
    let alwaysUseActionSheetForOnlineLinks = true
    let haveColorButtonImages = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100
}
