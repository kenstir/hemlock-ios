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

import Foundation

protocol AppConfiguration {
    var title: String { get }
    var url: String { get }
    var bugReportEmailAddress: String { get }
    var sort: String? { get }
    var detailsExtraLinkText: String? { get }
    var detailsExtraLinkFragment: String? { get }

    var enableHierarchicalOrgTree: Bool { get }
    var enableHoldShowQueuePosition: Bool { get }
    var enableHoldShowExpiration: Bool { get }
    var enableHoldPhoneNotification: Bool { get }
    var enablePartHolds: Bool { get }
    var enableTitleHoldOnItemWithParts: Bool { get }
    var enableMainSceneBottomToolbar: Bool { get }
    var enablePayFines: Bool { get }
    var enableHoursOfOperation: Bool { get }
    var enableMessages: Bool { get }

    var groupCopyInfoBySystem: Bool { get }
    var enableCopyInfoWebLinks: Bool { get }
    var needMARCRecord: Bool { get }
    var showOnlineAccessHostname: Bool { get }
    var alwaysPopupOnlineLinks: Bool { get }
    var haveColorButtonImages: Bool { get }

    var barcodeFormat: BarcodeFormat { get }
    var searchLimit: Int { get }
}
