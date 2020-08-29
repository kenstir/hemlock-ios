//
//  NobleAppConfiguration.swift
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

class NobleAppConfiguration: AppConfiguration {
    let title = "NOBLE Libraries"
    let url = "https://evergreen.noblenet.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    let sort: String? = "poprel"

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = false
    let enablePartHolds = false
    let enableTitleHoldOnItemWithParts = false
    let enableMainSceneBottomToolbar = false
    let enablePayFines = true
    let enableHoursOfOperation = false
    let enableMessages = false
    let groupCopyInfoBySystem = false
    let enableCopyInfoWebLinks = false
    let needMARCRecord = true
    let showOnlineAccessHostname = false
    let alwaysPopupOnlineLinks = true
    let haveColorButtonImages = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100
}
