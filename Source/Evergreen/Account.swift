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
import os.log

class Account {
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Account")
    private let lock = NSRecursiveLock()

    let username: String
    private(set) var password: String
    private(set) var authtoken: String?
    private(set) var userID: Int?
    private(set) var homeOrgID: Int?
    private(set) var barcode: String?
    private var dayPhone: String?
    private var firstGivenName: String?
    private var familyName: String?
    private(set) var expireDate: Date?
    private(set) var defaultNotifyEmail: Bool?
    private(set) var defaultNotifyPhone: Bool?
    private(set) var defaultNotifySMS: Bool?
    private(set) var bookBags: [BookBag] = []
    var patronLists: [any XPatronList] { return bookBags } //hack until I factor out Account model
    private(set) var bookBagsEverLoaded = false

    var displayName: String {
        if username == barcode,
            let first = firstGivenName,
            let last = familyName {
            return "\(first) \(last)"
        } else {
            return username
        }
    }

    private var userSettingsLoaded = false
    private var userSettingDefaultPickupLocation: Int?
    private var userSettingDefaultPhone: String?
    private var userSettingDefaultSearchLocation: Int?
    private var userSettingDefaultSMSCarrier: Int?
    private var userSettingDefaultSMSNotify: String?
    private(set) var userSettingCircHistoryStart: String?

    var notifyPhone: String? { return Utils.coalesce(userSettingDefaultPhone, dayPhone) }
    var pickupOrgID: Int? {
        get { return userSettingDefaultPickupLocation ?? homeOrgID }
        set { userSettingDefaultPickupLocation = newValue }
    }
    var searchOrgID: Int? { return userSettingDefaultSearchLocation ?? homeOrgID }
    var smsCarrier: Int? { return userSettingDefaultSMSCarrier }
    var smsNotify: String? { return userSettingDefaultSMSNotify }

    init(_ username: String, password: String) {
        self.username = username
        self.password = password
    }

    /// mt-safe
    func clear() -> Void {
        lock.lock(); defer { lock.unlock() }

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

    /// mt-safe
    func loadSession(fromObject obj: OSRFObject) {
        lock.lock(); defer { lock.unlock() }

        print("\(Utils.tt) loadSession")
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

    /// we just read `storedData` and `storedEnabledFlag` from the user settings.
    /// If what we have in the app is different, we need to update the user setting in Evergreen
    func maybeUpdateUserSettings(storedData: String?, storedEnabledFlag: Bool) async {
        print("[fcm] stored token was: \(storedData ?? "(nil)")")
        if let currentFCMToken = App.fcmNotificationToken,
           currentFCMToken != storedData || !storedEnabledFlag
        {
            print("[fcm] updating stored token")
            do {
                try await App.serviceConfig.userService.updatePushNotificationToken(account: self, token: currentFCMToken)
            } catch {
                print("[fcm] caught error \(error.localizedDescription)")
            }
        }
    }

    /// mt-safe
    func loadUserSettings(fromObject obj: OSRFObject) {
        lock.lock(); defer { lock.unlock() }
        print("\(Utils.tt) loadUserSettings")

        if let card = obj.getObject("card") {
            barcode = card.getString("barcode")
        }
        var holdNotifySetting = "email:phone" // OPAC default
        var storedPushNotificationData: String? = nil
        var storedPushNotificationEnabled = false
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
                    } else if name == API.userSettingHemlockPushNotificationData {
                        storedPushNotificationData = strvalue
                    } else if name == API.userSettingHemlockPushNotificationEnabled {
                        storedPushNotificationEnabled = (strvalue == "true")
                    }
                }
            }
        }
        parseHoldNotifyValue(holdNotifySetting)
        userSettingsLoaded = true

        Task { await maybeUpdateUserSettings(storedData: storedPushNotificationData, storedEnabledFlag: storedPushNotificationEnabled) }
        os_log(.info, log: Account.log, "loadUserSettings finished")
    }

    /// mt-safe
    func setCircHistoryStart(_ start: String?) {
        lock.lock(); defer { lock.unlock() }

        userSettingCircHistoryStart = start
    }

    /// mt-safe
    func loadBookBags(fromArray objects: [OSRFObject]) {
        lock.lock(); defer { lock.unlock() }

        bookBags = BookBag.makeArray(objects)
        Analytics.logEvent(event: Analytics.Event.bookbagsLoad, parameters: [Analytics.Param.numItems: bookBags.count])
        bookBagsEverLoaded = true
    }

    /// mt-safe
    func removeBookBag(at index: Int) {
        lock.lock(); defer { lock.unlock() }

        guard index >= 0 && index < bookBags.count else {
            return
        }
        bookBags.remove(at: index)
    }

    /// mt-safe
    func setAuthToken(_ authtoken: String) {
        lock.lock(); defer { lock.unlock() }

        self.authtoken = authtoken
    }
}
