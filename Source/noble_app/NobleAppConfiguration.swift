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

class NobleAppConfiguration: BaseAppConfiguration {
    override var title: String { return "NOBLE Libraries" }
    override var url: String { return "https://evergreen.noblenet.org" }
    override var bugReportEmailAddress: String { return "kenstir.apps@gmail.com" }
    override var sort: String? { return "poprel" }

    override var needMARCRecord: Bool { return true }
    override var alwaysUseActionSheetForOnlineLinks: Bool { return true }
    override var enableMainGridScene: Bool {
        if #available(iOS 14.0, *) {
            return true
        } else {
            return false
        }
    }

    override var searchLimit: Int { return 100 }
}
