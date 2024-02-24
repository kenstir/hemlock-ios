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

class HemlockAppConfiguration: BaseAppConfiguration {
    override var title: String { return "Hemlock" }
    override var url: String { return "http://192.168.1.8" }
    override var bugReportEmailAddress: String { return "kenstir.apps@gmail.com" }

    override var enableCheckoutHistory: Bool { return true }
    override var enableHierarchicalOrgTree: Bool { return true }
    override var enableHoldShowQueuePosition: Bool { return true }
    override var enableHoldShowExpiration: Bool { return true }
    override var enableHoldShowPickupLib: Bool { return false }
    override var enableHoldPhoneNotification: Bool { return true }
    override var enableHoldUseOverride: Bool { return false }
    override var enablePartHolds: Bool { return false }
    override var enableTitleHoldOnItemWithParts: Bool { return false }
    override var enableMainSceneBottomToolbar: Bool { return false }
    override var enablePayFines: Bool { return true }
    override var enableHoursOfOperation: Bool { return true }
    override var enableMessages: Bool { return false }
    override var enableEventsButton: Bool { return false }
    override var groupCopyInfoBySystem: Bool { return false }
    override var enableCopyInfoWebLinks: Bool { return true }
    override var needMARCRecord: Bool { return true }
    override var showOnlineAccessHostname: Bool { return true }
    override var alwaysUseActionSheetForOnlineLinks: Bool { return false }
    override var haveColorButtonImages: Bool { return false }

    override var barcodeFormat: BarcodeFormat { return .Disabled }
    override var searchLimit: Int { return 100 }
}
