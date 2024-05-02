/*
 * Copyright (c) 2024 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import Foundation

class PushNotification {
    /// userInfo as received from FCM
    var userInfo: [AnyHashable: Any]
    let title: String?
    let body: String?

    static let gcmMessageIDKey = "gcm.message_id"

    // these must agree with the [hemlock-sendmsg daemon](https://github.com/kenstir/hemlock-sendmsg)
    static let hemlockNotificationTypeKey = "hemlock.t"
    static let hemlockNotificationTypePMC = "pmc"
    static let hemlockNotificationUsernameKey = "hemlock.u"
    static let hemlockNotificationTagKey = "hemlock.tag" // for debugging

    var id: String {
        return userInfo[PushNotification.gcmMessageIDKey] as? String ?? "na"
    }
    var type: String {
        return userInfo[PushNotification.hemlockNotificationTypeKey] as? String ?? PushNotification.hemlockNotificationTypePMC
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
