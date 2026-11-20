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

    //static let account = Logger(subsystem: subsystem, category: "account")
    static let async = Logger(subsystem: subsystem, category: "async")
    static let data = Logger(subsystem: subsystem, category: "data") //low-level data issues
    static let fcm = Logger(subsystem: subsystem, category: "fcm") //firebase cloud messaging
    static let holds = Logger(subsystem: subsystem, category: "holds")
    static let lists = Logger(subsystem: subsystem, category: "lists")
    static let net = Logger(subsystem: subsystem, category: "net")
    static let orgs = Logger(subsystem: subsystem, category: "orgs")
    static let perf = Logger(subsystem: subsystem, category: "perf")
    static let state = Logger(subsystem: subsystem, category: "state")
    static let vc = Logger(subsystem: subsystem, category: "vc") //high-level view controller events

    /// debug log with public privacy
    func publicDebug(_ message: String) {
        self.log(level: .debug, "\(message, privacy: .public)")
    }

    /// info log with public privacy
    func publicInfo(_ message: String) {
        self.log(level: .info, "\(message, privacy: .public)")
    }

    /// error log with public privacy
    func publicError(_ message: String) {
        self.log(level: .error, "\(message, privacy: .public)")
    }
}

extension TimeInterval {
    /// Returns a string representation of the time interval in seconds with 3 decimal places.
    var ms: String {
        return String(format: "%.3f", self)
    }
}
