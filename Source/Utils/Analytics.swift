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

#if USE_FA || USE_FCM
typealias FA = FirebaseAnalytics.Analytics
#endif

class Analytics {
    static let nullTag = "null_tag"
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Analytics")
    static let lock = NSRecursiveLock()
    static var buf = RingBuffer<String>(count: 256)
//    static let maxBytesShown = 512
    static let maxBytesShown = 128

    class Event {
        static let bookbagAddItem = "bookbag_add_item"
        static let bookbagDeleteItem = "bookbag_delete_item"
        static let bookbagLoad = "bookbag_load"
        static let bookbagsLoad = "bookbags_load"
        static let historyLoad = "history_load"
        static let cancelHold = "hold_cancel"
        static let placeHold = "hold_place"
        static let updateHold = "hold_update"
        static let login = "login_v2"
        static let search = "search" // FirebaseAnalytics.AnalyticsEventSearch
        static let fcmTokenUpdate = "notification_token_update" // starts with "notification" to group it with related events in FA
    }

    class Param {
        // these need to be registered in FA as Custom Dimensions w/ scope=Event
        static let holdNotify = "hold_notify"
        static let holdPickupKey = "hold_pickup" // { home | other }
        static let holdSuspend = "hold_suspend" // bool
        static let loginType = "login_type" // { barcode | username }
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
    }

    class UserProperty {
        // these need to be registered in FA as Custom Dimensions w/ scope=User
        static let homeOrg = "user_home_org"
        static let multipleAccounts = "user_multiple_accounts" // bool
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
        if selectedOrg.id == App.serviceConfig.consortiumService.consortiumOrgID {
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

    /// Returns "true" or "false" to use as a value sent to analytics
    ///
    /// This is necessary because FA does not have real booleans, reports them as 0/1, and omits 0 values,
    /// resulting in missing dimension panels in the FA Events UI.
    static func boolValue(_ value: Bool) -> String {
        return value ? "true" : "false"
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
        let averageKeywordLength = (uniqueKeywordCount > 0) ? Int(round(10.0 * Double(totalLength) / Double(uniqueKeywordCount))) : 0

        return [
            Param.searchTermNumUniqueWords: uniqueKeywordCount,
            Param.searchTermAverageWordLengthX10: averageKeywordLength
        ]
    }

    /// mt: MT-Safe
    static private func logToBuffer(_ s: String) {
        lock.lock(); defer { lock.unlock() }
        buf.write(s)
    }

    /// log any error shown to the user to the ring buffer, to be included in an error report if any
    static func logError(_ error: Error) {
        os_log("[err] %{public}s", log: log, type: .error, error.localizedDescription)
        logToBuffer("[err] \(error.localizedDescription)")

        if case .shouldNotHappen = error as? HemlockError {
            logNonFatalEvent(error)
        }
    }

    /// log unexpected error and send it to Crashlytics as a non-fatal event
    /// mt: MT-Safe
    static func logNonFatalEvent(_ error: Error) {
#if USE_FA || USE_FCM
        Crashlytics.crashlytics().record(error: error)
#endif
    }

    static private func netPrefix(_ tag: String?) -> String {
        let tag8 = (tag ?? nullTag).padding(toLength: 8, withPad: " ", startingAt: 0)
        return "[net] \(tag8)"
    }

    /// mt: MT-Safe
    static func logRequest(tag: String?, method: String, args: [String]) {
        //print("\(Utils.tt) logRequest \(tag ?? nullTag): \(method)")

        // TODO: redact authtoken inside args
        var argsDescription = "***"
        if method != "open-ils.auth.authenticate.init",
           method != "open-ils.auth.authenticate.complete" {
            argsDescription = args.joined(separator: ",")
        }
        let prefix = netPrefix(tag)
        let s = "\(prefix) send  \(method) \(argsDescription)"

        os_log("%{public}s", log: log, type: .info, s)
        logToBuffer(s)
    }

    /// mt: MT-Safe
    static func logRequest(tag: String?, url: String) {
        let prefix = netPrefix(tag)
        let s = "\(prefix) send  \(url)"

        os_log("%{public}s", log: log, type: .info, s)
        logToBuffer(s)
    }

    /// mt: MT-Safe
    static func logResponse(tag: String?, data responseData: Data?, cached: Bool? = nil, elapsedMs: Int? = nil) {
        if let d = responseData,
            let s = String(data: d, encoding: .utf8) {
            logResponse(tag: tag, wireString: s, cached: cached, elapsedMs: elapsedMs)
        } else {
            logResponse(tag: tag, wireString: "(null)", cached: cached, elapsedMs: elapsedMs)
        }
    }

    /// mt: MT-Safe
    static func logResponse(tag: String?, wireString: String, cached: Bool? = nil, elapsedMs: Int? = nil) {
        //print("\(Utils.tt) logResponse \(tag ?? nullTag)")

        // build a prefix indicating cached status and elapsed time if available
        let netPrefix = netPrefix(tag)
        let duration: String
        if let ms = elapsedMs {
            duration = String(format: " %5d ms", ms)
        } else {
            duration = ""
        }
        let badge = cached == true ? "*" : " "
        let prefix = "\(netPrefix) recv\(badge)\(duration)"

        // redact certain responses: login (au), message (aum), orgTree (aou)
        // au? is sensitive; aou is just long
        let redactedResponseRegex = """
            ("__c":"aum?"|"__c":"aou")
            """
        let s: String
        if wireString.starts(with: "<IDL ") {
            s = "\(prefix) <IDL>"
        } else {
            let range = wireString.range(of: redactedResponseRegex, options: .regularExpression)
            if range == nil {
                s = "\(prefix) \(wireString)"
            } else {
                s = "\(prefix) ***"
            }
        }

        // log the first bytes of the response
        os_log("%{public}s", log: log, type: .info, s[0..<maxBytesShown])
        logToBuffer(s)
    }

    /// mt: MT-Safe
    static func clearLog() {
        lock.lock(); defer { lock.unlock() }
        buf.clear()
    }

    /// mt: MT-Safe
    static func getLog() -> String {
        lock.lock(); defer { lock.unlock() }
        let arr = buf.map { $0 }
        return arr.joined(separator: "\n") + "\n"
    }
}
