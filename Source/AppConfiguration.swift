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
    var detailsExtraLinkQuery: String? { get }
    var detailsExtraLinkFragment: String? { get }

    var enableCheckoutHistory: Bool { get }
    var enableHierarchicalOrgTree: Bool { get }
    var enableHoldShowQueuePosition: Bool { get }
    var enableHoldShowExpiration: Bool { get }
    var enableHoldShowPickupLib: Bool { get }
    var enableHoldPhoneNotification: Bool { get }
    var enableHoldUseOverride: Bool { get }
    var enablePartHolds: Bool { get }
    var enableTitleHoldOnItemWithParts: Bool { get }
    var enableMainSceneBottomToolbar: Bool { get }
    var enableMainGridScene: Bool { get }
    var enablePayFines: Bool { get }
    var enableHoursOfOperation: Bool { get }
    var enableMessages: Bool { get }
    var enableEventsButton: Bool { get }

    var groupCopyInfoBySystem: Bool { get }
    var enableCopyInfoWebLinks: Bool { get }
    var needMARCRecord: Bool { get }
    var showOnlineAccessHostname: Bool { get }
    var alwaysUseActionSheetForOnlineLinks: Bool { get }
    var haveColorButtonImages: Bool { get }

    var barcodeFormat: BarcodeFormat { get }
    var searchLimit: Int { get }
    var upcomingClosuresLimit: Int { get }
}

class BaseAppConfiguration: AppConfiguration {
    var title: String { return "Example Library" }
    var url: String { return "" }
    var bugReportEmailAddress: String { return "" }
    var sort: String? { return nil }
    var detailsExtraLinkText: String? { return nil }
    var detailsExtraLinkQuery: String? { return nil }
    var detailsExtraLinkFragment: String? { return nil }

    var enableCheckoutHistory: Bool { return true }
    var enableHierarchicalOrgTree: Bool { return true }
    var enableHoldShowQueuePosition: Bool { return true }
    var enableHoldShowExpiration: Bool { return true }
    var enableHoldShowPickupLib: Bool { return false }
    var enableHoldPhoneNotification: Bool { return false }
    var enableHoldUseOverride: Bool { return false }
    var enablePartHolds: Bool { return false }
    var enableTitleHoldOnItemWithParts: Bool { return false }
    var enableMainSceneBottomToolbar: Bool { return false }
    var enableMainGridScene: Bool { return false }
    var enablePayFines: Bool { return true }
    var enableHoursOfOperation: Bool { return true }
    var enableMessages: Bool { return false }
    var enableEventsButton: Bool { return false }
    var groupCopyInfoBySystem: Bool { return false }
    var enableCopyInfoWebLinks: Bool { return false }
    var needMARCRecord: Bool { return false }
    var showOnlineAccessHostname: Bool { return false }
    var alwaysUseActionSheetForOnlineLinks: Bool { return false }
    var haveColorButtonImages: Bool { return false }

    var barcodeFormat: BarcodeFormat { return .Codabar }
    var searchLimit: Int { return 200 }
    var upcomingClosuresLimit: Int { return 5 }
}
