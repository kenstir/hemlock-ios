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
    
    static func fetchServerVersion() -> Promise<GatewayResponse> {
        let req = Gateway.makeRequest(service: API.actor, method: API.ilsVersion, args: [], shouldCache: false)
        return req.gatewayResponse()
    }

    /// Fetch list of org types.
    static func fetchOrgTypes() -> Promise<Void> {
        if orgTypesLoaded {
            return Promise<Void>()
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTypesRetrieve, args: [], shouldCache: true)
        let promise = req.gatewayArrayResponse().done { array in
            OrgType.loadOrgTypes(fromArray: array)
            orgTypesLoaded = true
        }
        return promise
    }
    
    /// Fetch org tree.
    static func fetchOrgTree() -> Promise<Void> {
        if orgTreeLoaded {
            return Promise<Void>()
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTreeRetrieve, args: [], shouldCache: true)
        let promise = req.gatewayObjectResponse().done { obj in
            try Organization.loadOrganizations(fromObj: obj)
            orgTreeLoaded = true
        }
        return promise
    }
    
    /// Fetch one specific org unit.  We use this to fetch up-to-date (uncached) info on a specific org
    static func fetchOrg(forOrgID orgID: Int) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitRetrieve, args: [API.anonymousAuthToken, orgID], shouldCache: false)
        let promise = req.gatewayObjectResponse().done { obj in
            Organization.updateOrg(fromObj: obj)
        }
        return promise
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
                API.settingNotPickupLib,
                API.settingCreditPaymentsAllow,
                API.settingInfoURL,
                API.settingHemlockEventsURL,
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

    static func fetchOrgUnitHours(authtoken: String, forOrgID orgID: Int) -> Promise<(OSRFObject?)> {
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitHoursOfOperationRetrieve, args: [authtoken, orgID], shouldCache: false)
        return req.gatewayOptionalObjectResponse()
    }
    
    static func fetchOrgAddress(addressID: Int) -> Promise<(OSRFObject?)> {
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitAddressRetrieve, args: [addressID], shouldCache: true)
        return req.gatewayOptionalObjectResponse()
    }

    static func fetchUserSettings(account: Account) -> Promise<Void> {
        if account.userSettingsLoaded {
            return Promise<Void>()
        }
        guard let authtoken = account.authtoken,
            let userID = account.userID else {
            //TODO: analytics
            return Promise<Void>()
        }
        let fields = ["card", "settings"]
        let req = Gateway.makeRequest(service: API.actor, method: API.userFleshedRetrieve, args: [authtoken, userID, fields], shouldCache: false)
        let promise = req.gatewayResponse().done { resp in
            if let obj = resp.obj {
                account.loadUserSettings(fromObject: obj)
            }
        }
        return promise
    }

    static func fetchBookBags(account: Account, authtoken: String, userID: Int) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.actor, method: API.containerRetrieveByClass, args: [authtoken, userID, API.containerClassBiblio, API.containerTypeBookbag], shouldCache: false)
        let promise = req.gatewayArrayResponse().done { array in
            account.loadBookBags(fromArray: array)
        }
        return promise
    }

    static func fetchBookBagContents(authtoken: String, bookBag: BookBag) -> Promise<Void> {
        let query = "container(bre,bookbag,\(bookBag.id),\(authtoken))"
        let options = ["limit": 999]
        let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 0], shouldCache: false)
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            bookBag.initVisibleIds(fromQueryObj: obj)
            let req2 = Gateway.makeRequest(service: API.actor, method: API.containerFlesh, args: [authtoken, API.containerClassBiblio, bookBag.id], shouldCache: false)
            return req2.gatewayObjectResponse()
        }.done { obj in
            bookBag.loadItems(fromFleshedObj: obj)
        }
        return promise
    }
    
    static func createBookBag(authtoken: String, userID: Int, name: String) -> Promise<Void> {
        let obj = OSRFObject([
            "btype": API.containerTypeBookbag,
            "name": name,
            "pub": false,
            "owner": userID,
        ], netClass: "cbreb")
        let req = Gateway.makeRequest(service: API.actor, method: API.containerCreate, args: [authtoken, API.containerClassBiblio, obj], shouldCache: false)
        let promise = req.gatewayResponse().done { resp in
            if let str = resp.str {
                os_log("[bookbag] createBag %@ result %@", name, str)
            }
        }
        return promise
    }
    
    static func deleteBookBag(authtoken: String, bookBagId: Int) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.actor, method: API.containerDelete, args: [authtoken, API.containerClassBiblio, bookBagId], shouldCache: false)
        let promise = req.gatewayResponse().done { resp in
            if let str = resp.str {
                os_log("[bookbag] bag %d deleteBag result %@", bookBagId, str)
            }
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

    static func fetchMessages(authtoken: String, userID: Int) -> Promise<([OSRFObject])> {
        let req = Gateway.makeRequest(service: API.actor, method: API.messagesRetrieve, args: [authtoken, userID], shouldCache: false)
        return req.gatewayArrayResponse()
    }

    static private func markMessageAction(authtoken: String, messageID: Int, action: String) -> Promise<Void> {
        var url = App.library?.url ?? ""
        url += "/eg/opac/myopac/messages?action=\(action)&message_id=\(messageID)"
        let req = Gateway.makeOPACRequest(url: url, authtoken: authtoken, shouldCache: false)
        let promise = req.responseData().done { data, pmkresponse in
            // we ignore the response, the entire messages web page
        }
        return promise
    }

    static func markMessageDeleted(authtoken: String, messageID: Int) -> Promise<Void> {
        return markMessageAction(authtoken: authtoken, messageID: messageID, action: "mark_deleted")
    }

    static func markMessageRead(authtoken: String, messageID: Int) -> Promise<Void> {
        return markMessageAction(authtoken: authtoken, messageID: messageID, action: "mark_read")
    }

    static func markMessageUnread(authtoken: String, messageID: Int) -> Promise<Void> {
        return markMessageAction(authtoken: authtoken, messageID: messageID, action: "mark_unread")
    }
}
