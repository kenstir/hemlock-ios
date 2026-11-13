//
//  Copyright (c) 2026 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import OSLog

extension Logger {
    private static let subsystem = Bundle.appIdentifier

    static let app = Logger(subsystem: subsystem, category: "app")
    static let async = Logger(subsystem: subsystem, category: "async")
    static let fcm = Logger(subsystem: subsystem, category: "fcm")
    static let net = Logger(subsystem: subsystem, category: "net")
    static let orgs = Logger(subsystem: subsystem, category: "orgs")
    static let state = Logger(subsystem: subsystem, category: "state")
}
