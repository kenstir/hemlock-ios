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

class AppState {
    class Str {
        static let holdPhoneNumber = "phoneNumber"
        static let holdSMSNumber = "SMSNumber"

        static let listSortBy = "listSortBy"

        static let searchClass = "searchClass"
        static let searchFormat = "searchFormat"
        static let searchOrgShortName = "searchOrg"
    }
    class Boolean {
        static let holdNotifyByEmail = "notifyByEmail"
        static let holdNotifyByPhone = "notifyByPhone"
        static let holdNotifyBySMS = "notifyBySMS"

        static let listSortDesc = "listSortDesc" // "t" or "f"
    }
    class Integer {
        static let holdSMSCarrierID = "SMSCarrierID"
        static let holdPickupOrgID = "pickupOrgID"
    }

    static func sensitiveString(forKey key: String) -> String? {
        // We use Valet for sensitive strings like phone numbers
        if let value = App.valet.string(forKey: key) {
            print("[state] Got sensitive \(key) = ***")
            return value
        }
        return nil
    }

    static func string(forKey key: String) -> String? {
        if let value = UserDefaults.standard.string(forKey: key) {
            print("[state] Got \(key) = \(value)")
            return value
        }
        return nil
    }

    static func bool(forKey key: String) -> Bool? {
        // Use ``object(forKey:)`` so we can tell the difference between "not set" and "set to false"
        if let value = UserDefaults.standard.object(forKey: key) as? Bool {
            print("[state] Got \(key) = \(value)")
            return value
        }
        return nil
    }

    static func integer(forKey key: String) -> Int? {
        // Use ``object(forKey:)`` so we can tell the difference between "not set" and "set to 0"
        if let value = UserDefaults.standard.object(forKey: key) as? Int {
            print("[state] Got \(key) = \(value)")
            return value
        }
        return nil
    }

    static func set(sensitiveString string: String, forKey key: String) {
        // We use Valet for sensitive strings like phone numbers
        print("[state] Set sensitive \(key) to ***")
        App.valet.set(string: string, forKey: key)
    }

    static func set(string: String, forKey key: String) {
        print("[state] Set \(key) to \(string)")
        UserDefaults.standard.set(string, forKey: key)
    }

    static func set(bool: Bool, forKey key: String) {
        print("[state] Set \(key) to \(bool)")
        UserDefaults.standard.set(bool, forKey: key)
    }

    static func set(integer: Int, forKey key: String) {
        print("[state] Set \(key) to \(integer)")
        UserDefaults.standard.set(integer, forKey: key)
    }

    /// migrate old settings from Valet to UserDefaults
    static func migrateLegacySettings() {
        migrateOneSetting(from: "sortBy", to: AppState.Str.listSortBy)
        migrateOneSetting(from: "sortDesc", toBool: AppState.Boolean.listSortDesc)
        migrateOneSetting(from: "SMSCarrier", toInteger: AppState.Integer.holdSMSCarrierID)
    }
    static func migrateOneSetting(from oldKey: String, to newKey: String) {
        if let val = App.valet.string(forKey: oldKey) {
            print("[state] migrate \(oldKey) = \(val) to newKey \(newKey)")
            UserDefaults.standard.set(val, forKey: newKey)
            App.valet.removeObject(forKey: oldKey)
        }
    }
    static func migrateOneSetting(from oldKey: String, toBool newKey: String) {
        if let val = App.valet.string(forKey: oldKey) {
            let boolVal = (val == "t")
            print("[state] migrate \(oldKey) = \(boolVal) to newKey \(newKey)")
            UserDefaults.standard.set(boolVal, forKey: newKey)
            App.valet.removeObject(forKey: oldKey)
        }
    }
    static func migrateOneSetting(from oldKey: String, toInteger newKey: String) {
        if let val = App.valet.string(forKey: oldKey), let intVal = Int(val) {
            print("[state] migrate \(oldKey) = \(intVal) to newKey \(newKey)")
            UserDefaults.standard.set(intVal, forKey: newKey)
            App.valet.removeObject(forKey: oldKey)
        }
    }
}
