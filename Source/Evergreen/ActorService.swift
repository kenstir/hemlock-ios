//
//  ActorService.swift
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
import PromiseKit
import os.log

class ActorService {
    static var orgTypesLoaded = false
    static var orgTreeLoaded = false

    /// Load  list of org types.
    static func loadOrgTypesAsync() async throws -> Void {
        if orgTypesLoaded {
            return
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTypesRetrieve, args: [], shouldCache: true)
        let array = try await req.gatewayResponseAsync().asArray()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            OrgType.loadOrgTypes(fromArray: array)
            orgTypesLoaded = true
        }
    }

    /// Loads the org tree
    static func loadOrgTreeAsync() async throws -> Void {
        if orgTreeLoaded {
            return
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTreeRetrieve, args: [], shouldCache: true)
        let obj = try await req.gatewayResponseAsync().asObject()
        // TODO: make mt-safe, remove await
        try await MainActor.run {
            try Organization.loadOrganizations(fromObj: obj)
            orgTreeLoaded = true
        }
    }

    /// TODO: remove after transition
    static func fetchOrgTree() -> Promise<Void> {
        return Promise<Void>()
    }

    /// fetch settings for all organizations.
    /// Must be called only after `orgTreeLoaded`.
    /// If `forOrgID` is non-nil, it means load settings for just the one org.
    static private func fetchOrgSettings(forOrgID: Int?) -> [Promise<Void>] {
        var promises: [Promise<Void>] = []
        for org in Organization.visibleOrgs {
            if org.areSettingsLoaded {
                continue
            }
            if let id = forOrgID {
                if id != org.id {
                    continue
                }
            }
            var settings = [
                API.settingCreditPaymentsAllow,
                API.settingInfoURL,
                API.settingNotPickupLib,
                API.settingHemlockEresourcesURL,
                API.settingHemlockEventsURL,
                API.settingHemlockMeetingRoomsURL,
                API.settingHemlockMuseumPassesURL,
            ]
            if org.parent == nil {
                settings.append(API.settingSMSEnable)
            }
            let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [org.id, settings, API.anonymousAuthToken], shouldCache: true)
            let promise = req.gatewayObjectResponse().done { obj in
                org.loadSettings(fromObj: obj)
            }
            promises.append(promise)
        }
        return promises
    }
    
    // fetch org tree and settings for all orgs
    static func fetchOrgTreeAndSettings(forOrgID orgID: Int? = nil) -> Promise<Void> {
        let start = Date()

        let promise = fetchOrgTree().then { () -> Promise<Void> in
            let elapsed = -start.timeIntervalSinceNow
            os_log("orgTree.elapsed: %.3f (%.3f)", elapsed, Gateway.addElapsed(elapsed))
            let promises: [Promise<Void>] = self.fetchOrgSettings(forOrgID: orgID)
            return when(fulfilled: promises)
        }
        return promise
    }

    static func addItemToBookBag(authtoken: String, bookBagId: Int, recordId: Int) -> Promise<Void> {
        let obj = OSRFObject([
            "bucket": bookBagId,
            "target_biblio_record_entry": recordId,
            "id": nil,
        ], netClass: "cbrebi")
        let req = Gateway.makeRequest(service: API.actor, method: API.containerItemCreate, args: [authtoken, API.containerClassBiblio, obj], shouldCache: false)
        let promise = req.gatewayResponse().done { resp in
            if let str = resp.str {
                os_log("[bookbag] bag %d addItem %d result %@", bookBagId, recordId, str)
            }
        }
        return promise
    }
    
    static func removeItemFromBookBag(authtoken: String, bookBagItemId: Int) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.actor, method: API.containerItemDelete, args: [authtoken, API.containerClassBiblio, bookBagItemId], shouldCache: false)
        let promise = req.gatewayResponse().done { resp in
            if let str = resp.str {
                os_log("[bookbag] removeItem %d result %@", bookBagItemId, str)
            }
        }
        return promise
    }

    static func fetchCheckoutHistory(authtoken: String) -> Promise<[OSRFObject]> {
        let req = Gateway.makeRequest(service: API.actor, method: API.checkoutHistory, args: [authtoken], shouldCache: true)
        return req.gatewayMaybeEmptyArrayResponse()
    }

    /// returns "1" or an error
    static func updatePatronSettings(authtoken: String, userID: Int, settings: JSONDictionary) -> Promise<String> {
        let req = Gateway.makeRequest(service: API.actor, method: API.patronSettingsUpdate, args: [authtoken, userID, settings], shouldCache: false)
        return req.gatewayStringResponse()
    }

    static func enableCheckoutHistory(account: Account) -> Promise<Void> {
        guard let authtoken = account.authtoken,
            let userID = account.userID else {
            return Promise<Void>()
        }
        let dateString = OSRFObject.apiDayOnlyFormatter.string(from: Date())
        let settings: JSONDictionary = [API.userSettingCircHistoryStart: dateString]
        let promise = updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings).then { (str: String) -> Promise<Void> in
            // `str` doesn't matter, it either worked or it errored.
            account.setCircHistoryStart(dateString)
            return Promise<Void>()
        }
        return promise
    }

    static func disableCheckoutHistory(account: Account) -> Promise<Void> {
        guard let authtoken = account.authtoken,
            let userID = account.userID else {
            return Promise<Void>()
        }
        let dateString: String? = nil
        let settings: JSONDictionary = [API.userSettingCircHistoryStart: dateString]
        let promise = updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings).then { (str: String) -> Promise<Void> in
            // `str` doesn't matter, it either worked or it errored.
            account.setCircHistoryStart(dateString)
            return Promise<Void>()
        }
        return promise
    }

    static func updatePushNotificationToken(account: Account, token: String) -> Promise<Void> {
        guard let authtoken = account.authtoken,
            let userID = account.userID else {
            return Promise<Void>()
        }
        let settings: JSONDictionary = [
            API.userSettingHemlockPushNotificationData: token,
            API.userSettingHemlockPushNotificationEnabled: true
        ]
        let promise = updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings).then { (str: String) -> Promise<Void> in
            // `str` doesn't matter, it either worked or it errored.
            // TODO: do we have anything to do here?
            print("[fcm] token updated str=\(str)")
            return Promise<Void>()
        }
        return promise
    }
}
