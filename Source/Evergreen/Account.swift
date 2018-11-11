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

class Account {
    let username: String
    var password: String
    var authtoken: String?
    var authtokenExpiryDate: Date?
    var userID: Int?
    var homeOrgID: Int?
    var barcode: String?
    var defaultNotifyEmail: Bool?
    var defaultNotifyPhone: Bool?
    var defaultNotifySMS: Bool?

    fileprivate var userSettingDefaultPickupLocation: Int?
    fileprivate var userSettingDefaultPhone: String?
    fileprivate var userSettingDefaultSearchLocation: Int?
    fileprivate var userSettingDefaultSMSCarrier: Int?
    fileprivate var userSettingDefaultSMSNotify: String?

    var phone: String? { return userSettingDefaultPhone }
    var pickupOrgID: Int? {
        if let id = userSettingDefaultPickupLocation {
            return id
        }
        return homeOrgID
    }
    var searchOrgID: Int? {
        if let id = userSettingDefaultSearchLocation {
            return id
        }
        return homeOrgID
    }
    var smsCarrier: Int? { return userSettingDefaultSMSCarrier }
    var smsNotify: String? { return userSettingDefaultSMSNotify }
    
    init(_ username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func loadFromAuthResponse(_ fromObj: OSRFObject?) throws -> Void {
        guard
            let obj = fromObj,
            let payload = obj.getObject("payload"),
            let authtoken = payload.getString("authtoken"),
            let authtime = payload.getInt("authtime") else
        {
           throw HemlockError.unexpectedNetworkResponse("Unexpected response to login")
        }
        
        self.authtoken = authtoken
        self.authtokenExpiryDate = Date(timeIntervalSinceNow: TimeInterval(authtime))
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
    
    func loadUserSettings(fromObject obj: OSRFObject) {
        if let card = obj.getObject("card") {
            barcode = card.getString("barcode")
        }
        if let settings = obj.getAny("settings") as? [OSRFObject] {
            for setting in settings {
                if let name = setting.getString("name"),
                    let strvalue = removeStupidExtraQuotes(setting.getString("value"))
                {
                    print("setting=\(setting) name=\(name) value=\(strvalue)")
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
                        parseHoldNotifyValue(strvalue)
                    }
                }
            }
        }
    }
    
    func clearCredentials() -> Void {
        self.password = ""
        self.authtoken = nil
        self.authtokenExpiryDate = nil
        self.userID = nil
    }
}
