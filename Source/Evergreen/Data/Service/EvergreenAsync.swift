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

class EvergreenAsync {

    //MARK: - Pcrud

    static func fetchBRE(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveBRE, args: [API.anonymousAuthToken, id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    static func fetchMRA(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymousAuthToken, id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    //MARK: - Search

    static func fetchMetarecordMODS(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.search, method: API.metarecordModsRetrieve, args: [id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    static func fetchRecordMODS(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

}
