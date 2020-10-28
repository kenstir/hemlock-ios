//
//  Analytics.swift
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
import os.log

enum AnalyticsErrorCode {
    case shouldNotHappen
}

class Analytics {
    static let log = OSLog(subsystem: "net.kenstir.apps.hemlock", category: "Analytics")
    static var buf = RingBuffer<String>(count: 256)

    static func logError(code: AnalyticsErrorCode, msg: String, file: String, line: Int) {
        os_log("%s:%d: %s", log: log, type: .info, file, line, msg)
        let s = "\(file):\(line): \(msg)"
        buf.write(s)
    }
    
    static func logRequest(method: String, args: [Any?]) {
        // TODO: redact authtoken inside args
        var argsDescription = "?"
        if let jsonData = try? JSONSerialization.data(withJSONObject: args),
            let str = String(data: jsonData, encoding: .utf8) {
            argsDescription = str
        }
        let s = "send: \(method) \(argsDescription)"

        os_log("%s", log: log, type: .info, s)
        buf.write(s)
    }
    
    static func logResponse(_ wireString: String) {
        // redact certain responses: login (au), message (aum), orgTree (aou)
        let pattern = """
            ("__c":"aum?"|"__c":"aou")
            """
        let range = wireString.range(of: pattern, options: .regularExpression)
        var s: String = "recv: ***"
        if range == nil {
            s = "recv: \(wireString)"
        }

        os_log("%s", log: log, type: .info, s)
        buf.write(s)
    }
    
    static func clearLog() {
        buf.clear()
    }
    
    static func getLog() -> String {
        let arr = buf.map { $0 }
        return arr.joined(separator: "\n") + "\n"
    }
}
