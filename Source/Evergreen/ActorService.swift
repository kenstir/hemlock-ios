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

    static func fetchCheckoutHistory(authtoken: String) async throws -> [OSRFObject] {
        let req = Gateway.makeRequest(service: API.actor, method: API.checkoutHistory, args: [authtoken], shouldCache: true)
        return try await req.gatewayResponseAsync().asMaybeEmptyArray()
    }
}
