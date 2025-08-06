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

class EvergreenOrgService: XOrgService {
    func loadOrgSettings(forOrgID orgID: Int) async throws {
        guard let org = Organization.find(byId: orgID) else {
            throw HemlockError.internalError("org \(orgID) not found")
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
        let obj = try await req.gatewayResponseAsync().asObject()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            org.loadSettings(fromObj: obj)
        }
    }

    func loadOrgDetails(account: Account, forOrgID orgID: Int) async throws {
        guard let org = Organization.find(byId: orgID) else {
            throw HemlockError.internalError("org \(orgID) not found")
        }

        // async 1: reload org without caching
        let orgReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitRetrieve, args: [API.anonymousAuthToken, org.id], shouldCache: false)
        async let orgResp = orgReq.gatewayResponseAsync()

        // async 2: load org hours
        let hoursReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitHoursOfOperationRetrieve, args: [account.authtoken, org.id], shouldCache: false)
        async let hoursResp = hoursReq.gatewayResponseAsync()

        // async 3: load org closures
        let param: JSONDictionary = ["orgid": orgID]
        let closuresReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitHoursClosedRetrieve, args: [account.authtoken, param], shouldCache: false)
        async let closuresResp = closuresReq.gatewayResponseAsync()

        // async 4: load address
        let addressReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitAddressRetrieve, args: [org.addressID], shouldCache: false)
        async let addressResp = addressReq.gatewayResponseAsync()

        // await responses in parallel
        let (orgObj, hoursObj, closures, addressObj) = try await (orgResp.asObject(), hoursResp.asObjectOrNil(), closuresResp.asMaybeEmptyArray(), addressResp.asObjectOrNil())

        // load data
        org.updateOrg(fromObj: orgObj)
        org.loadHours(fromObj: hoursObj)
        org.setAddress(fromObj: addressObj)
        org.loadClosures(fromArray: closures)
    }
}
