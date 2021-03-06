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
                API.settingInfoURL
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
}
