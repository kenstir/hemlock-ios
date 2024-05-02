 //  Account.swift
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

class Account {
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Account")

    let username: String
    var password: String
    var authtoken: String?
    var userID: Int?
    var homeOrgID: Int?
    var barcode: String?
    var dayPhone: String?
    var firstGivenName: String?
    var familyName: String?
    var expireDate: Date?
    var defaultNotifyEmail: Bool?
    var defaultNotifyPhone: Bool?
    var defaultNotifySMS: Bool?
    var bookBags: [BookBag] = []
    var bookBagsEverLoaded = false
    
    var displayName: String {
        if username == barcode,
            let first = firstGivenName,
            let last = familyName {
            return "\(first) \(last)"
        } else {
            return username
        }
    }

    var userSettingsLoaded = false
    fileprivate var userSettingDefaultPickupLocation: Int?
    fileprivate var userSettingDefaultPhone: String?
    fileprivate var userSettingDefaultSearchLocation: Int?
    fileprivate var userSettingDefaultSMSCarrier: Int?
    fileprivate var userSettingDefaultSMSNotify: String?
    var userSettingCircHistoryStart: String?

    var notifyPhone: String? { return Utils.coalesce(userSettingDefaultPhone, dayPhone) }
    var pickupOrgID: Int? { return userSettingDefaultPickupLocation ?? homeOrgID }
    var searchOrgID: Int? { return userSettingDefaultSearchLocation ?? homeOrgID }
    var smsCarrier: Int? { return userSettingDefaultSMSCarrier }
    var smsNotify: String? { return userSettingDefaultSMSNotify }

    init(_ username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func clear() -> Void {
        self.password = ""
        self.authtoken = nil
        self.userID = nil
        self.homeOrgID = nil
        self.barcode = nil
        self.dayPhone = nil
        self.userSettingsLoaded = false
        self.bookBags = []
        self.bookBagsEverLoaded = false
    }

    func loadSession(fromObject obj: OSRFObject) {
        userID = obj.getInt("id")
        homeOrgID = obj.getInt("home_ou")
        dayPhone = obj.getString("day_phone")
        firstGivenName = obj.getString("pref_first_given_name") ?? obj.getString("first_given_name")
        familyName = obj.getString("pref_family_name") ?? obj.getString("family_name")
        expireDate = obj.getDate("expire_date")
    }
    
    // Fix stupid setting that is returned with extra quotes, e.g. Int 52 in
    // {"__c":"aus","__p":[1854914,"opac.default_sms_carrier",4212142,"\"52\""]}
    private func removeStupidExtraQuotes(_ value: String?) -> String? {
        if let s = value {
            return s.trimQuotes()
        } else {
            return nil
        }
    }
    
    private func parseHoldNotifyValue(_ value: String) {
        // value is "|" or ":" separated, e.g. "email|sms" or "phone:email"
        defaultNotifyEmail = value.contains("email")
        defaultNotifyPhone = value.contains("phone")
        defaultNotifySMS = value.contains("sms")
    }

    /// we just got the fcmToken from the user setting.  If the one we have in the app is
    /// different, we need to update the user setting in Evergreen
    func maybeUpdateStoredToken(storedFCMToken: String?) {
        print("[fcm] stored token:  \(storedFCMToken ?? "(nil)")")
        if let currentFCMToken = App.fcmNotificationToken,
           currentFCMToken != storedFCMToken
        {
            let promise = ActorService.updatePushNotificationToken(account: self, token: currentFCMToken)
            promise.done {
                print("[fcm] done updating stored token")
            }.catch { error in
                print("[fcm] caught error \(error.localizedDescription)")
            }
        }
    }

    func loadUserSettings(fromObject obj: OSRFObject) {
        if let card = obj.getObject("card") {
            barcode = card.getString("barcode")
        }
        var holdNotifySetting = "email:phone" // OPAC default
        var storedFCMToken: String? = nil
        if let settings = obj.getAny("settings") as? [OSRFObject] {
            for setting in settings {
                if let name = setting.getString("name"),
                    let strvalue = removeStupidExtraQuotes(setting.getString("value"))
                {
                    print("name=\(name) value=\(strvalue) was=\(setting.getString("value") ?? "nil")")
                    if name == API.userSettingDefaultPickupLocation, let value = Int(strvalue) {
                        userSettingDefaultPickupLocation = value
                    } else if name == API.userSettingDefaultPhone {
                        userSettingDefaultPhone = strvalue
                    } else if name == API.userSettingDefaultSearchLocation, let value = Int(strvalue) {
                        userSettingDefaultSearchLocation = value
                    } else if name == API.userSettingDefaultSMSCarrier, let value = Int(strvalue) {
                        userSettingDefaultSMSCarrier = value
                    } else if name == API.userSettingDefaultSMSNotify {
                        userSettingDefaultSMSNotify = strvalue
                    } else if name == API.userSettingHoldNotify {
                        holdNotifySetting = strvalue
                    } else if name == API.userSettingCircHistoryStart {
                        userSettingCircHistoryStart = strvalue
                    } else if name == API.usereSettingHemlockPushNotificationData {
                        storedFCMToken = strvalue
                    }
                }
            }
        }
        parseHoldNotifyValue(holdNotifySetting)
        userSettingsLoaded = true

        maybeUpdateStoredToken(storedFCMToken: storedFCMToken)
        os_log(.info, log: Account.log, "loadUserSettings finished, fcmToken=%@", App.fcmNotificationToken ?? "(nil)")
    }

    func loadBookBags(fromArray objects: [OSRFObject]) {
        bookBags = BookBag.makeArray(objects)
        bookBagsEverLoaded = true
    }
}
