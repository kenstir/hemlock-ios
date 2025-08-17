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

class EvergreenCircService: XCircService {
    func fetchCheckouts(account: Account) async throws -> [CircRecord] {
        let req = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [account.authtoken, account.userID], shouldCache: false)
        let obj = try await req.gatewayResponseAsync().asObject()
        return CircRecord.makeArray(fromObj: obj)
    }

    func loadCheckoutDetails(account: Account, circRecord: CircRecord) async throws {
        let circReq = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [account.authtoken, circRecord.id], shouldCache: false)
        let circObj = try await circReq.gatewayResponseAsync().asObject()
        circRecord.setCircObj(circObj)

        if let modsObj = try await fetchCopyMods(copyId: circRecord.targetCopy) {
            circRecord.setMetabibRecord(MBRecord(mvrObj: modsObj))
        }

        if let record = circRecord.metabibRecord {
            let mraObj = try await fetchMRA(id: record.id)
            record.update(fromMraObj: mraObj)
        }
    }

    private func fetchCopyMods(copyId: Int) async throws -> OSRFObject? {
        guard copyId != -1 else { return nil }
        let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [copyId], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    func fetchMRA(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymousAuthToken, id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    func renewCheckout(account: Account, targetCopy: Int) async throws -> Bool {
        let options: JSONDictionary = [
            "patron": account.userID,
            "copyid": targetCopy,
            "opac_renewal": 1
        ]
        let req = Gateway.makeRequest(service: API.circ, method: API.renew, args: [account.authtoken, options], shouldCache: false)
        let _ = try await req.gatewayResponseAsync().asObject()
        return true
    }
}
