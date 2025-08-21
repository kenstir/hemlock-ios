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

class EvergreenCircService: XCircService {
    let log = OSLog(subsystem: Bundle.appIdentifier, category: "Circ")

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

    func fetchRecordMods(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    func fetchMetarecordMods(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.search, method: API.metarecordModsRetrieve, args: [id], shouldCache: true)
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

    func fetchCheckoutHistory(account: Account) async throws -> [HistoryRecord] {
        throw HemlockError.notImplemented
    }

    func loadHistoryDetails(historyRecord: HistoryRecord) async throws {
        throw HemlockError.notImplemented
    }

    func fetchHolds(account: Account) async throws -> [HoldRecord] {
        let req = Gateway.makeRequest(service: API.circ, method: API.holdsRetrieve, args: [account.authtoken, account.userID], shouldCache: false)
        let array = try await req.gatewayResponseAsync().asArray()
        return HoldRecord.makeArray(array)
    }

    func loadHoldDetails(account: Account, hold: HoldRecord) async throws {
        guard let holdTarget = hold.target,
              let holdType = hold.holdType,
              let authtoken = account.authtoken else
        {
            return
        }
        if holdType == API.holdTypeTitle {
            try await loadTitleHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == API.holdTypeMetarecord {
            try await loadMetarecordHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == API.holdTypePart {
            try await loadPartHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == API.holdTypeCopy || hold.holdType == API.holdTypeForce || hold.holdType == API.holdTypeRecall {
            try await loadCopyHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == API.holdTypeVolume {
            try await loadVolumeHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else {
            os_log("[hold] target=%d holdType=%@ NOT HANDLED", log: log, type: .info, holdTarget, holdType)
            return
        }
    }

    func loadTitleHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=T start", log: log, type: .info, holdTarget)
        let obj = try await fetchRecordMods(id: holdTarget)
        let record = MBRecord(id: holdTarget, mvrObj: obj)
        let mraObj = try await fetchMRA(id: record.id)
        record.update(fromMraObj: mraObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=T done", log: log, type: .info, holdTarget)
    }

    func loadMetarecordHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=M start", log: log, type: .info, holdTarget)
        let obj = try await fetchMetarecordMods(id: holdTarget)
        let record = MBRecord(id: obj.getInt("tcn") ?? -1, mvrObj: obj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=M done", log: log, type: .info, holdTarget)
    }

    func loadPartHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
//        os_log("[hold] target=%d holdType=P fielder start", log: log, type: .info, holdTarget)
//        var param: [String: Any] = [:]
//        param["cache"] = 1
//        param["fields"] = ["label", "record"]
//        param["query"] = ["id": holdTarget]
//        let req = Gateway.makeRequest(service: API.fielder, method: API.fielderBMPAtomic, args: [param], shouldCache: false)
//        let promise = req.gatewayArrayResponse().then { (array: [OSRFObject]) -> Promise<(OSRFObject)> in
//            guard let obj = array.first,
//                let target = obj.getInt("record") else
//            {
//                throw HemlockError.unexpectedNetworkResponse("Failed to load fields for part hold")
//            }
//            hold.label = obj.getString("label")
//            os_log("[hold] target=%d holdType=P targetRecord=%d fielder done mods start", log: log, type: .info, holdTarget, target)
//            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [target], shouldCache: true).gatewayObjectResponse()
//        }.done { (obj: OSRFObject) -> Void in
//            os_log("[hold] target=%d holdType=P mods done", log: log, type: .info, holdTarget)
//            guard let id = obj.getInt("doc_id") else { throw HemlockError.unexpectedNetworkResponse("Failed to find doc_id for part hold") }
//            hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
//        }
//        return promise
    }

    func loadCopyHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
//        os_log("[hold] target=%d holdType=T asset start", log: log, type: .info, holdTarget)
//        let req = Gateway.makeRequest(service: API.search, method: API.assetCopyRetrieve, args: [holdTarget], shouldCache: true)
//        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
//            guard let callNumber = obj.getID("call_number") else { throw HemlockError.unexpectedNetworkResponse("Failed to find call_number for copy hold") }
//            os_log("[hold] target=%d holdType=T call start", log: log, type: .info, holdTarget)
//            return Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [callNumber], shouldCache: true).gatewayObjectResponse()
//        }.then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
//            guard let id = obj.getID("record") else { throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for copy hold") }
//            os_log("[hold] target=%d holdType=T mods start", log: log, type: .info, holdTarget)
//            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [id], shouldCache: true).gatewayObjectResponse()
//        }.done { (obj: OSRFObject) -> Void in
//            os_log("[hold] target=%d holdType=P mods done", log: log, type: .info, holdTarget)
//            guard let id = obj.getInt("doc_id") else { throw HemlockError.unexpectedNetworkResponse("Failed to find doc_id for copy hold") }
//            hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
//        }
//        return promise
    }

    func loadVolumeHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
//        os_log("[hold] target=%d holdType=V call start", log: log, type: .info, holdTarget)
//        let req = Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [holdTarget], shouldCache: true)
//        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
//            guard let id = obj.getID("record") else { throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for volume hold")}
//            os_log("[hold] target=%d holdType=V mods start", log: log, type: .info, holdTarget)
//            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [id], shouldCache: true).gatewayObjectResponse()
//        }.done { (obj: OSRFObject) -> Void in
//            os_log("[hold] target=%d holdType=V mods done", log: log, type: .info, holdTarget)
//            guard let id = obj.getInt("doc_id") else { throw HemlockError.unexpectedNetworkResponse("Failed to find doc_id for volume hold") }
//            hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
//        }
//        return promise
    }

    func loadHoldQueueStats(hold: HoldRecord, authtoken: String) async throws {
//        guard let id = hold.ahrObj.getID("id") else {
//            return Promise<Void>() //TODO: add analytics
//        }
//        let holdTarget = hold.target ?? 0
//        os_log("fetchQueueStats target=%d start", log: log, type: .info, holdTarget)
//        let req = Gateway.makeRequest(service: API.circ, method: API.holdQueueStats, args: [authtoken, id], shouldCache: false)
//        let promise = req.gatewayObjectResponse().done { obj in
//            os_log("fetchQueueStats target=%d done", log: log, type: .info, holdTarget)
//            hold.qstatsObj = obj
//        }
//        return promise
    }


    func fetchHoldParts(targetId: Int) async throws -> [XHoldPart] {
        throw HemlockError.notImplemented
    }

    func fetchTitleHoldIsPossible(account: Account, targetId: Int, pickupOrgId: Int) async throws -> Bool {
        throw HemlockError.notImplemented
    }

    func placeHold(account: Account, targetId: Int, withOptions options: XHoldOptions) async throws -> Bool {
        throw HemlockError.notImplemented
    }

    func cancelHold(account: Account, holdId: Int) async throws -> Bool {
        throw HemlockError.notImplemented
    }
}
