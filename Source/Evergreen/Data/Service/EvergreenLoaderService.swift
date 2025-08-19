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

class EvergreenLoaderService: XLoaderService {
    func loadStartupPrerequisites(options: LoadStartupOptions) async throws {
        let start = Date()

        // sync: cache keys must be established first, before IDL is loaded
        Gateway.setClientCacheKey(options.clientCacheKey)
        try await loadServerCacheKey()

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

    private func loadServerCacheKey() async throws {
        // async: launch these two in parallel
        let versionReq = Gateway.makeRequest(service: API.actor, method: API.ilsVersion, args: [], shouldCache: false)

        let settings = [API.settingHemlockCacheKey]
        let cacheKeyReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [Organization.consortiumOrgID, settings, API.anonymousAuthToken], shouldCache: false)

        // await both responses in parallel
        async let versionResp = try versionReq.gatewayResponseAsync()
        async let settingsResp = try cacheKeyReq.gatewayResponseAsync()
        let (version, settingsObj) = try await (versionResp.asString(), settingsResp.asObject())
        let settingsVal = Organization.ousGetString(settingsObj, API.settingHemlockCacheKey)
        Gateway.setServerCacheKey(serverVersion: version, serverHemlockCacheKey: settingsVal)
    }

    private func loadIDL() async throws {
        let req = Gateway.makeRequest(url: Gateway.idlURL(), shouldCache: true)
        let data = try await req.gatewayDataResponseAsync()
        // TODO: make mt-safe, remove await
        await MainActor.run {
            let _ = App.loadIDL(fromData: data)
        }
    }

    private func loadOrgTypes() async throws {
        try await ActorService.loadOrgTypesAsync()
    }

    private func loadOrgTree() async throws {
        try await ActorService.loadOrgTreeAsync()
    }

    private func loadCopyStatuses() async throws {
        try await SearchService.loadCopyStatusesAsync()
    }

    private func loadCodedValueMaps() async throws {
        try await PCRUDService.loadCodedValueMapsAsync()
    }

    func loadPlaceHoldPrerequisites() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await PCRUDService.loadSMSCarriersAsync() }
            for org in Organization.visibleOrgs {
                if !org.areSettingsLoaded {
                    group.addTask {
                        try await App.serviceConfig.orgService.loadOrgSettings(forOrgID: org.id)
                    }
                }
            }

            try await group.waitForAll()
        }
    }
}
