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

//enum FetchState {
//    case notrun, running, done
//}

class ActorService {
    static var orgTypesLoaded = false
    static var orgTreeLoaded = false

    /// Fetch list of org types.
    static func fetchOrgTypesArray() -> Promise<Void> {
        if orgTypesLoaded {
            return Promise<Void>()
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTypesRetrieve, args: [])
        let promise = req.gatewayArrayResponse().done { array in
            OrgType.loadOrgTypes(fromArray: array)
            orgTypesLoaded = true
        }
        return promise
    }
    
    /// Fetch org tree.
    /*
    static func fetchOrgTree() -> Promise<Void> {
        if orgTreeLoaded {
            return Promise<Void>()
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTreeRetrieve, args: [])
        let promise = req.gatewayObjectResponse().done { obj in
            try Organization.loadOrganizations(fromObj: obj)
            orgTreeLoaded = true
        }
        return promise
    }
    */
    
    /// fetch settings for all organizations.
    /// Must be called only after `orgTreeLoaded`.
    static private func fetchOrgSettings() -> [Promise<Void>] {
        var promises: [Promise<Void>] = []
        for org in Organization.orgs {
            if org.areSettingsLoaded {
                continue
            }
            var settings = [API.settingNotPickupLib, API.settingCreditPaymentsAllow]
            if org.parent == nil {
                settings.append(API.settingSMSEnable)
            }
            let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [org.id, settings, API.anonymousAuthToken])
            let promise = req.gatewayObjectResponse().done { obj in
                org.loadSettings(fromObj: obj)
            }
            promises.append(promise)
        }
        return promises
    }
    
    // fetch org tree and settings for all orgs
    static func fetchOrgs() -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTreeRetrieve, args: [])
        let start = Date()
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<Void> in
            try Organization.loadOrganizations(fromObj: obj)
            let elapsed = -start.timeIntervalSinceNow
            os_log("orgTreeRetrieve.elapsed: %.3f", elapsed)
            orgTreeLoaded = true
            let promises: [Promise<Void>] = self.fetchOrgSettings()
            return when(fulfilled: promises)
        }
        return promise
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
        let req = Gateway.makeRequest(service: API.actor, method: API.userFleshedRetrieve, args: [authtoken, userID, fields])
        let promise = req.gatewayResponse().done { resp, pmkresp in
            if let obj = resp.obj {
                account.loadUserSettings(fromObject: obj)
            }
        }
        return promise
    }
}
