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

class PinesAppConfiguration: BaseAppConfiguration {
    override var title: String { return "PINES" }
    override var url: String { return "https://gapines.org" }
    override var bugReportEmailAddress: String { return "kenstir.apps@gmail.com" }
    override var detailsExtraLinkText: String? { return "More Information" }
    override var detailsExtraLinkQuery: String? { return nil }
    override var detailsExtraLinkFragment: String? { return "awards" }

    override var enableFirebase: Bool { return true }
    override var enableHoldShowQueuePosition: Bool { return false }
    override var enableHoldShowExpiration: Bool { return false }
    override var enableHoldPhoneNotification: Bool { return true }
    override var enableHoldShowPickupLib: Bool { return true }
    override var enablePartHolds: Bool { return true }
    override var enableTitleHoldOnItemWithParts: Bool { return true }
    override var enableMainSceneBottomToolbar: Bool { return true }
    override var enableMessages: Bool { return true }
    override var groupCopyInfoBySystem: Bool { return true }
    override var enableCopyInfoWebLinks: Bool { return true }
    override var needMARCRecord: Bool { return true }
    override var alwaysUseActionSheetForOnlineLinks: Bool { return true }

    override var searchLimit: Int { return 100 }
}
