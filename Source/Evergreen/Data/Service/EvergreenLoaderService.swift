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

        // sync: load the org tree
        try await loadOrgTree()

        os_log("startup.elapsed: %.3f", log: Gateway.log, type: .info, -start.timeIntervalSinceNow)
    }

    private func loadServerCacheKey() async throws {
        // async: launch these two in parallel
        let versionReq = Gateway.makeRequest(service: API.actor, method: API.ilsVersion, args: [], shouldCache: false)

        let settings = [API.settingHemlockCacheKey]
        let cacheKeyReq = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [Organization.consortiumOrgID, settings, API.anonymousAuthToken], shouldCache: false)

        // await both responses
        let version = try await versionReq.gatewayResponseAsync().asString()
        let settingsObj = try await cacheKeyReq.gatewayResponseAsync().asObject()
        let settingsVal = Organization.ousGetString(settingsObj, API.settingHemlockCacheKey)
        Gateway.setServerCacheKey(serverVersion: version, serverHemlockCacheKey: settingsVal)
    }

    private func loadIDL() async throws {
        let req = Gateway.makeRequest(url: Gateway.idlURL(), shouldCache: true)
        let data = try await req.gatewayDataResponseAsync()
        // TODO: maybe await MainActor.run here?
        let _ = App.loadIDL(fromData: data)
    }

    private func loadOrgTree() async throws {
        try await ActorService.loadOrgTreeAsync()
    }

    func loadPlaceHoldPrerequisites() async throws {
        throw HemlockError.notImplemented
    }
}
