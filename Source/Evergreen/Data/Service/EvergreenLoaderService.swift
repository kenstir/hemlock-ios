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

class EvergreenLoaderService: LoaderService {
    func loadStartupPrerequisites(options: LoaderServiceOptions) async throws {
        let start = Date()

        // sync: cache keys must be established first, before IDL is loaded
        Gateway.setClientCacheKey(options.clientCacheKey)
        let serverCacheKey = try await loadGlobalOrgSettings()
        Gateway.setServerCacheKey(serverCacheKey)

        // sync: load the IDL next, because everything else depends on it
        try await loadIDL()

        // async: everything else can be done in parallel
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.loadOrgTypes() }
            group.addTask { try await self.loadOrgTree() }
            group.addTask { try await self.loadCopyStatuses() }
            group.addTask { try await self.loadCodedValueMaps() }

            try await group.waitForAll()
        }

        os_log("startup.elapsed: %.3f", log: Gateway.log, type: .info, -start.timeIntervalSinceNow)
    }

    private func loadGlobalOrgSettings() async throws -> String {
        // async: launch these two in parallel
        let versionReq = Gateway.makeRequest(service: API.actor, method: API.ilsVersion, args: [], shouldCache: false)

        let settings = [
            API.settingHemlockCacheKey,
            API.settingAlertBannerShow,
            API.settingAlertBannerText,
            API.settingSMSEnable,
        ]
        let settingsReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [EvergreenOrganization.consortiumOrgID, settings, API.anonymousAuthToken], shouldCache: false)

        // await both responses in parallel
        async let versionResp = try versionReq.gatewayResponseAsync()
        async let settingsResp = try settingsReq.gatewayResponseAsync()
        let (version, settingsObj) = try await (versionResp.asString(), settingsResp.asObject())

        // parse out the settings values
        let hemlockCacheKey = EvergreenOrganization.ousGetString(settingsObj, API.settingHemlockCacheKey)
        EvergreenOrganization.alertBannerText = EvergreenOrganization.ousGetString(settingsObj, API.settingAlertBannerText)
        EvergreenOrganization.alertBannerShow = EvergreenOrganization.ousGetBool(settingsObj, API.settingAlertBannerShow) ?? false
        EvergreenOrganization.isSMSEnabledSetting = EvergreenOrganization.ousGetBool(settingsObj, API.settingSMSEnable) ?? false

        // include the hemlockCacheKey in the serverCacheKey if set
        let serverCacheKey: String
        if let val = hemlockCacheKey {
            serverCacheKey = "\(version)-\(val)"
        } else {
            serverCacheKey = version
        }
        return serverCacheKey
    }

    private func loadIDL() async throws {
        let req = Gateway.makeRequest(url: Gateway.idlURL(), shouldCache: true)
        let data = try await req.gatewayDataResponseAsync()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            let _ = loadIDL(fromData: data)
        }
    }

    private func loadIDL(fromData data: Data) -> Bool {
        let parser = IDLParser(data: data)
        let ok = parser.parse()
        return ok
    }

    private func loadOrgTypes() async throws {
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTypesRetrieve, args: [], shouldCache: true)
        let array = try await req.gatewayResponseAsync().asArray()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            OrgType.loadOrgTypes(fromArray: array)
        }
    }

    private func loadOrgTree() async throws {
        let req = Gateway.makeRequest(service: API.actor, method: API.orgTreeRetrieve, args: [], shouldCache: true)
        let obj = try await req.gatewayResponseAsync().asObject()
        // TODO: make mt-safe, remove await
        try await MainActor.run {
            try EvergreenOrganization.loadOrganizations(fromObj: obj)
        }
    }

    private var copyStatusesLoaded = false
    private func loadCopyStatuses() async throws {
        if copyStatusesLoaded {
            return
        }
        let req = Gateway.makeRequest(service: API.search, method: API.copyStatusRetrieveAll, args: [], shouldCache: true)
        let array = try await req.gatewayResponseAsync().asArray()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            CopyStatus.loadCopyStatus(fromArray: array)
            copyStatusesLoaded = true
        }
    }

    private var ccvmLoaded = false
    private func loadCodedValueMaps() async throws {
        if ccvmLoaded {
            return
        }
        let query: [String: Any] = ["ctype": ["icon_format", "search_format"]]
        let req = Gateway.makeRequest(service: API.pcrud, method: API.searchCCVM, args: [API.anonymousAuthToken, query], shouldCache: true)
        let array = try await req.gatewayResponseAsync().asArray()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            CodedValueMap.load(fromArray: array)
            ccvmLoaded = true
        }
    }

    func loadPlaceHoldPrerequisites() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.loadSMSCarriersAsync() }
            for visibleOrg in EvergreenOrganization.visibleOrgs {
                if let org = visibleOrg as? EvergreenOrganization,
                   !org.areSettingsLoaded
                {
                    group.addTask {
                        try await App.svc.org.loadOrgSettings(forOrgID: org.id)
                    }
                }
            }

            try await group.waitForAll()
        }
    }

    private var carriersLoaded = false
    func loadSMSCarriersAsync() async throws {
        if carriersLoaded {
            return
        }
        let options: [String: Any] = ["active": 1]
        let req = Gateway.makeRequest(service: API.pcrud, method: API.searchSMSCarriers, args: [API.anonymousAuthToken, options], shouldCache: true)
        let array = try await req.gatewayResponseAsync().asArray()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            EvergreenSMSCarrier.loadSMSCarriers(fromArray: array)
            carriersLoaded = true
        }
    }
}
