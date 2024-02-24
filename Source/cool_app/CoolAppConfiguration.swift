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

class CoolAppConfiguration: BaseAppConfiguration {
    override var title: String { return "COOL" }
    override var url: String { return "https://evergreen.cool-cat.org" }
    override var bugReportEmailAddress: String { return "kenstir.apps@gmail.com" }
    override var detailsExtraLinkText: String? { return "Additional Content" }
    override var detailsExtraLinkQuery: String? { return "expand=addedcontent;ac=summary" }
    override var detailsExtraLinkFragment: String? { return "addedcontent" }

    override var enableHoldPhoneNotification: Bool { return true }
    override var enablePayFines: Bool { return false }
    override var enableEventsButton: Bool { return true }
    override var enableCopyInfoWebLinks: Bool { return true }
    override var showOnlineAccessHostname: Bool { return true }

    override var searchLimit: Int { return 100 }
}
