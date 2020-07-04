//
//  HemlockAppConfiguration.swift
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

class HemlockAppConfiguration: AppConfiguration {
    let title = "Hemlock"
    //let url = "https://kenstir.ddns.net"
    let url = "http://192.168.1.4"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    let sort: String? = nil

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = true
    let enablePartHolds = false
    let enableMainSceneBottomToolbar = false
    let enablePayFines = true
    let groupCopyInfoBySystem = false
    let enableCopyInfoWebLinks = true
    let needMARCRecord = false
    let showOnlineAccessHostname = true
    let alwaysPopupOnlineLinks = false
    let haveColorButtonImages = false

    let barcodeFormat: BarcodeFormat = .Disabled
    let searchLimit = 100
}
