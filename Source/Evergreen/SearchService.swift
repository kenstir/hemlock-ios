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
import PMKAlamofire

class SearchService {

    static func fetchCopyCount(recordID: Int, orgID: Int) async throws -> [OSRFObject] {
        let req = Gateway.makeRequest(service: API.search, method: API.copyCount, args: [orgID, recordID], shouldCache: false)
        return try await req.gatewayResponseAsync().asArray()
    }

    static func fetchCopyLocationCounts(recordID: Int, org: Organization?) -> Promise<(GatewayResponse)> {
        var args: [Any] = [recordID]
        if let searchOrg = org {
            args.append(searchOrg.id)
            args.append(searchOrg.level)
        }
        let req = Gateway.makeRequest(service: API.search, method: API.copyLocationCounts, args: args, shouldCache: false)
        let promise = req.gatewayResponse()
        return promise
    }

    static func fetchRecordMODS(forRecord record: MBRecord) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [record.id], shouldCache: true)
        let promise = req.gatewayObjectResponse().done { obj in
            record.setMvrObj(obj)
        }
        return promise
    }

    static func fetchHoldParts(recordID: Int) async throws -> [OSRFObject] {
        let param: JSONDictionary = [
            "record": recordID
        ]
        let req = Gateway.makeRequest(service: API.search, method: API.holdParts, args: [param], shouldCache: true)
        return try await req.gatewayResponseAsync().asArray()
    }
}
