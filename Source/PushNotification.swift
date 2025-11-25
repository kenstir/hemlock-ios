//
//  Copyright (c) 2025 Kenneth H. Cox
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

import Foundation

// NB: This list of strings must be kept in sync in 3 places:
// * hemlock (android): core/src/main/java/org/evergreen_ils/data/PushNotification.kt
// * hemlock-ios:       Source/Models/PushNotification.swift
// * hemlock-sendmsg:   sendmsg.go
enum NotificationType: String {
    case checkouts = "checkouts"
    case fines = "fines"
    case general = "general"
    case holds = "holds"
    case pmc = "pmc"
}

class PushNotification {
    /// userInfo as received from FCM
    var userInfo: [AnyHashable: Any]
    let title: String?
    let body: String?

    static let gcmMessageIDKey = "gcm.message_id"

    // these type keys must agree with the [hemlock-sendmsg daemon](https://github.com/kenstir/hemlock-sendmsg)
    static let hemlockNotificationTypeKey = "hemlock.t"
    static let hemlockNotificationUsernameKey = "hemlock.u"

    static let hemlockNotificationTagKey = "hemlock.tag" // for debugging

    var id: String {
        return userInfo[PushNotification.gcmMessageIDKey] as? String ?? "na"
    }
    var type: NotificationType {
        if let typeString = userInfo[PushNotification.hemlockNotificationTypeKey] as? String,
           let typeVal = NotificationType(rawValue: typeString) {
            return typeVal
        }
        return NotificationType.holds
    }
    var username: String? {
        return userInfo[PushNotification.hemlockNotificationUsernameKey] as? String
    }
    /*** debug tag to track notifications by origin.  We store it userInfo so it can be passed through the NotificationCenter. */
    var tag: String? {
        get {
            return userInfo[PushNotification.hemlockNotificationTagKey] as? String
        }
        set {
            userInfo[PushNotification.hemlockNotificationTagKey] = newValue
        }
    }
    var isNotGeneral: Bool {
        return type != NotificationType.general
    }

    init(userInfo: [AnyHashable : Any]) {
        self.userInfo = userInfo

        // get body and title from aps/alert
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: String]
        title = alert?["title"]
        body = alert?["body"]
    }
}

extension PushNotification: CustomDebugStringConvertible {
    var debugDescription: String {
        return "id:\(id) user:\(username ?? "(nil)") title:\(title ?? "(nil)") body:\(body ?? "(nil)") tag:\(tag ?? "")"
    }
}
