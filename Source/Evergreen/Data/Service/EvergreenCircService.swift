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

    func fetchBMP(holdTarget: Int) async throws -> OSRFObject {
        var param: [String: Any] = [:]
        param["cache"] = 1
        param["fields"] = ["label", "record"]
        param["query"] = ["id": holdTarget]
        let req = Gateway.makeRequest(service: API.fielder, method: API.fielderBMPAtomic, args: [param], shouldCache: false)
        let array = try await req.gatewayResponseAsync().asArray()
        guard let obj = array.first else {
            throw HemlockError.unexpectedNetworkResponse("Failed to load details for hold target \(holdTarget)")
        }
        return obj
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

        // Determine which function to call based on the hold type
        var loadFunc: (_ hold: HoldRecord, _ holdTarget: Int, _ authtoken: String) async throws -> Void
        if holdType == API.holdTypeTitle {
            loadFunc = loadTitleHoldTargetDetails
        } else if hold.holdType == API.holdTypeMetarecord {
            loadFunc = loadMetarecordHoldTargetDetails
        } else if hold.holdType == API.holdTypePart {
            loadFunc = loadPartHoldTargetDetails
        } else if hold.holdType == API.holdTypeCopy || hold.holdType == API.holdTypeForce || hold.holdType == API.holdTypeRecall {
            loadFunc = loadCopyHoldTargetDetails
        } else if hold.holdType == API.holdTypeVolume {
            loadFunc = loadVolumeHoldTargetDetails
        } else {
            os_log("[hold] target=%d holdType=%@ NOT HANDLED", log: log, type: .info, holdTarget, holdType)
            return
        }
        let loadHoldTargetDetails = loadFunc

        // Load the hold target details and queue stats in parallel
        async let details: Void = loadHoldTargetDetails(hold, holdTarget, authtoken)
        async let qstats: Void = loadHoldQueueStats(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        _ = try await (details, qstats)
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
        os_log("[hold] target=%d holdType=P start", log: log, type: .info, holdTarget)
        let obj = try await fetchBMP(holdTarget: holdTarget)
        guard let target = obj.getInt("record") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to load fields for part hold")
        }
        hold.setLabel(obj.getString("label"))

        let modsObj = try await fetchRecordMods(id: target)
        let record = MBRecord(mvrObj: modsObj)
        let mraObj = try await fetchMRA(id: record.id)
        record.update(fromMraObj: mraObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=P done", log: log, type: .info, holdTarget)
    }

    func loadCopyHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=C start", log: log, type: .info, holdTarget)
        let acpReq = Gateway.makeRequest(service: API.search, method: API.assetCopyRetrieve, args: [holdTarget], shouldCache: true)
        let acpObj = try await acpReq.gatewayResponseAsync().asObject()
        guard let callNumber = acpObj.getID("call_number") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to find call_number for copy hold")
        }

        let acnReq = Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [callNumber], shouldCache: true)
        let acnObj = try await acnReq.gatewayResponseAsync().asObject()
        guard let id = acnObj.getID("record") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for copy hold")
        }

        let modsObj = try await fetchRecordMods(id: id)
        let record = MBRecord(mvrObj: modsObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=C done", log: log, type: .info, holdTarget)
    }

    func loadVolumeHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=V start", log: log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [holdTarget], shouldCache: true)
        let obj = try await req.gatewayResponseAsync().asObject()
        guard let id = obj.getID("record") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for volume hold")
        }

        let modsObj = try await fetchRecordMods(id: id)
        let record = MBRecord(mvrObj: modsObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=V done", log: log, type: .info, holdTarget)
    }

    func loadHoldQueueStats(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        guard let id = hold.ahrObj.getID("id") else { return }

        os_log("[hold] target=%d qstats start", log: log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.circ, method: API.holdQueueStats, args: [authtoken, id], shouldCache: false)
        let obj = try await req.gatewayResponseAsync().asObject()
        hold.setQstatsObj(obj)
        os_log("[hold] target=%d qstats done", log: log, type: .info, holdTarget)
    }

    func fetchHoldParts(targetId: Int) async throws -> [XHoldPart] {
        throw HemlockError.notImplemented
    }

    func fetchTitleHoldIsPossible(account: Account, targetId: Int, pickupOrgId: Int) async throws -> Bool {
        let complexParam: JSONDictionary = [
            "patronid": account.userID,
            "pickup_lib": pickupOrgId,
            "hold_type": API.holdTypeTitle,
            "titleid": targetId,
        ]
        let req = Gateway.makeRequest(service: API.circ, method: API.titleHoldIsPossible, args: [account.authtoken, complexParam], shouldCache: false)
        // The response is a JSON object with details, e.g. "success":1.  But if a title hold is not possible,
        // the response includes an event, and asObject() will throw.
        let _ = try await req.gatewayResponseAsync().asObject()
        os_log("[hold] target=%d titleHoldIsPossible=true", log: log, type: .info, targetId)
        return true
    }

    func placeHold(account: Account, targetId: Int, withOptions options: XHoldOptions) async throws -> Bool {
        throw HemlockError.notImplemented
    }

    func cancelHold(account: Account, holdId: Int) async throws -> Bool {
        let note = "Cancelled by mobile app"
        let req = Gateway.makeRequest(service: API.circ, method: API.holdCancel, args: [account.authtoken, holdId, nil, note], shouldCache: false)
        // holdCancel returns "1" on success, and an error event if it fails.
        let str = try await req.gatewayResponseAsync().asString()
        os_log("[hold] id=%d holdCancel result=%@", log: log, type: .info, holdId, str)
        return true
    }
}
