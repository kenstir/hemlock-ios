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
#if USE_FA || USE_FCM
import FirebaseAnalytics
import FirebaseCrashlytics
#endif

enum AnalyticsErrorCode {
    case shouldNotHappen
}

#if USE_FA || USE_FCM
typealias FA = FirebaseAnalytics.Analytics
#endif

class Analytics {
    static let nullTag = "nil"
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Analytics")
    static var buf = RingBuffer<String>(count: 256)

    class Event {
        static let bookbagAddItem = "bookbag_add_item"
        static let bookbagDeleteItem = "bookbag_delete_item"
        static let bookbagLoad = "bookbag_load"
        static let bookbagsLoad = "bookbags_load"
        static let cancelHold = "hold_cancel"
        static let placeHold = "hold_place"
        static let updateHold = "hold_update"
        static let login = "login"
        static let search = "search" // FirebaseAnalytics.AnalyticsEventSearch
    }

    class Param {
        // these need to be registered in FA as Custom Dimensions w/ scope=Event
        static let holdNotify = "hold_notify"
        static let holdPickupKey = "hold_pickup" // { home | other }
        static let holdSuspend = "hold_suspend"
        static let result = "result"
        static let searchClass = "search_class"
        static let searchFormat = "search_format"
        static let searchOrgKey = "search_org" // { home | other }
        //static let searchTerm = "search_term" // FirebaseAnalytics.AnalyticsParameterSearchTerm omitted for privacy

        // these need to be registered in FA as Custom Metrics
        static let numAccounts = "num_accounts"
        static let numItems = "num_items"
        static let numResults = "num_results"
        static let searchTermNumUniqueWords = "search_term_uniq_words"
        static let searchTermAverageWordLengthX10 = "search_term_avg_word_len_x10"

        // boolean params do not need to be registered
        static let multipleAccounts = "multiple_accounts"
    }

    class UserProperty {
        // these need to be registered in FA as Custom Dimensions w/ scope=User
        static let homeOrg = "user_home_org"
        static let parentOrg = "user_parent_org"
    }

    class Value {
        static let ok = "ok"
        static let unset = ""
    }

    static func logEvent(event: String, parameters: [String: Any]) {
        let s = String(describing: parameters)
        os_log("[fa] logEvent %@ %@", event, s)
#if USE_FA || USE_FCM
        FA.logEvent(event, parameters: parameters)
#endif
    }

    static func setUserProperty(value: String?, forName name: String) {
#if USE_FA || USE_FCM
        FA.setUserProperty(value, forName: name)
#endif
    }

    static func orgDimension(selectedOrg: Organization?, defaultOrg: Organization?, homeOrg: Organization?) -> String {
        guard let selectedOrg, let defaultOrg, let homeOrg else {
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

    static func loginTypeDimension(username: String, barcode: String?) -> String {
        if username == barcode {
            return "barcode"
        }
        return "username"
    }

    static func searchTermParameters(searchTerm: String) -> [String: Int] {
        // Extract words
        var keywords: [String] = []
        for word in searchTerm.lowercased().components(separatedBy: .whitespaces) {
            let cleanedWord = word.replacingOccurrences(of: "\\W+", with: "", options: .regularExpression)
            if !cleanedWord.isEmpty {
                keywords.append(cleanedWord)
            }
        }

        // Calculate unique keywords
        let uniqueKeywords = Set(keywords)
        let uniqueKeywordCount = uniqueKeywords.count

        // Calculate average keyword length
        let totalLength = uniqueKeywords.reduce(0) { $0 + $1.count }
        let averageKeywordLength = Int(round(10.0 * Double(totalLength) / Double(uniqueKeywordCount)))

        return [
            Param.searchTermNumUniqueWords: uniqueKeywordCount,
            Param.searchTermAverageWordLengthX10: averageKeywordLength
        ]
    }

    static func logError(code: AnalyticsErrorCode, msg: String, file: String, line: Int) {
        os_log("%{public}s:%d: %{public}s", log: log, type: .error, file, line, msg)
        let s = "\(file):\(line): \(msg)"
        buf.write(s)
    }

    static func logError(error: Error) {
        os_log("%{public}s", log: log, type: .error, error.localizedDescription)
        buf.write(error.localizedDescription)
#if USE_FA || USE_FCM
        Crashlytics.crashlytics().record(error: error)
#endif
    }

    static func logRequest(tag: String, method: String, args: [String]) {
        // TODO: redact authtoken inside args
        var argsDescription = "***"
        if method != "open-ils.auth.authenticate.init",
           method != "open-ils.auth.authenticate.complete" {
            argsDescription = args.joined(separator: ",")
        }
        let s = "\(tag): send: \(method) \(argsDescription)"

        os_log("%{public}s", log: log, type: .info, s)
        buf.write(s)
    }

    static func logRequest(tag: String, url: String) {
        let s = "\(tag): send: \(url)"

        os_log("%{public}s", log: log, type: .info, s)
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
        // au? is sensitive; aou is just long
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
        os_log("%{public}s", log: log, type: .info, s[0..<256])
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
