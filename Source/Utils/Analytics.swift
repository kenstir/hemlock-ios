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
#if USE_FA
import FirebaseAnalytics
#endif

enum AnalyticsErrorCode {
    case shouldNotHappen
}

#if USE_FA
typealias FA = FirebaseAnalytics.Analytics
#endif

class Analytics {
    static let nullTag = "nil"
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Analytics")
    static var buf = RingBuffer<String>(count: 256)

    class Event {
        static let login = "login"
        static let search = "search" // FirebaseAnalytics.AnalyticsEventSearch
    }

    class Param {
        static let homeOrg = "home_org"
        static let numAccounts = "num_accounts"
        static let numResults = "num_results"
        static let parentOrg = "parent_org"
        static let result = "result"
        static let searchClass = "search_class"
        static let searchFormat = "search_format"
        static let searchOrgKey = "search_org" // { home | other }
        static let searchTerm = "search_term" // FirebaseAnalytics.AnalyticsParameterSearchTerm
    }

    class Value {
        static let ok = "ok"
        static let unknown = "?"
    }

    static func logEvent(event: String, parameters: [String: Any]) {
    #if USE_FA
        let s = String(describing: parameters)
        os_log("[fa] logEvent %@ %@", event, s)
        FA.logEvent(event, parameters: parameters)
    #endif
    }

    static func orgDimensionKey(selectedOrg s: Organization?, defaultOrg d: Organization?, homeOrg h: Organization?) -> String {
        guard let selectedOrg = s, let defaultOrg = d, let homeOrg = h else {
            return "null"
        }
        if selectedOrg.id == defaultOrg.id {
            return "default"
        }
        if selectedOrg.id == homeOrg.id {
            return "home"
        }
        if selectedOrg.isConsortium {
            return selectedOrg.shortname
        }
        return "other"
    }

    static func loginTypeKey(username: String, barcode: String?) -> String {
        if username == barcode {
            return "barcode"
        }
        return "username"
    }

    static func logError(code: AnalyticsErrorCode, msg: String, file: String, line: Int) {
        os_log("%s:%d: %s", log: log, type: .info, file, line, msg)
        let s = "\(file):\(line): \(msg)"
        buf.write(s)
    }

    static func logRequest(tag: String, method: String, args: [String]) {
        // TODO: redact authtoken inside args
        var argsDescription = "***"
        if method != "open-ils.auth.authenticate.init",
           method != "open-ils.auth.authenticate.complete" {
            argsDescription = args.joined(separator: ",")
        }
        let s = "\(tag): send: \(method) \(argsDescription)"

        os_log("%s", log: log, type: .info, s)
        buf.write(s)
    }
    
    static func logResponse(tag: String, data responseData: Data?) {
        if let d = responseData,
            let s = String(data: d, encoding: .utf8) {
            logResponse(tag: tag, wireString: s)
        } else {
            logResponse(tag: tag, wireString: "(null)")
        }
    }
    
    static func logResponse(tag: String, wireString: String) {
        // redact certain responses: login (au), message (aum), orgTree (aou)
        let pattern = """
            ("__c":"aum?"|"__c":"aou")
            """
        let range = wireString.range(of: pattern, options: .regularExpression)
        let s: String
        if range == nil {
            s = "\(tag): recv: \(wireString)"
        } else {
            s = "\(tag): recv: ***"
        }

        // log the first bytes of the response
        // TODO: indicate if cached
        os_log("%s", log: log, type: .info, s[0..<256])
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
