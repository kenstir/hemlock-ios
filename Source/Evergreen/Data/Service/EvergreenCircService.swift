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

        let modsObj = try await fetchCopyMODS(copyId: circRecord.targetCopy)
        let record = MBRecord(mvrObj: modsObj)
        circRecord.setMetabibRecord(record)

        if record.isPreCat {
            let acpObj = try await fetchACP(id: circRecord.targetCopy)
            circRecord.setAcpObj(acpObj)
        } else {
            let mraObj = try await EvergreenAsync.fetchMRA(id: record.id)
            record.update(fromMraObj: mraObj)
        }
    }

    private func fetchCopyMODS(copyId: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [copyId], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    private func fetchACN(id: Int) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [id], shouldCache: true)
        return try await req.gatewayResponseAsync().asObject()
    }

    private func fetchACP(id: Int) async throws -> OSRFObject {
        let acpReq = Gateway.makeRequest(service: API.search, method: API.assetCopyRetrieve, args: [id], shouldCache: true)
        return try await acpReq.gatewayResponseAsync().asObject()
    }

    private func fetchBMP(holdTarget: Int) async throws -> OSRFObject {
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
        let targetCopy = historyRecord.targetCopy
        let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [targetCopy], shouldCache: true)
        let modsObj = try await req.gatewayResponseAsync().asObject()
        historyRecord.setBibRecord(MBRecord(mvrObj: modsObj))
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
        async let modsTask = EvergreenAsync.fetchRecordMODS(id: holdTarget)
        async let mraTask = EvergreenAsync.fetchMRA(id: holdTarget)
        let (obj, mraObj) = try await (modsTask, mraTask)

        let record = MBRecord(id: holdTarget, mvrObj: obj)
        record.update(fromMraObj: mraObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=T done", log: log, type: .info, holdTarget)
    }

    func loadMetarecordHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=M start", log: log, type: .info, holdTarget)
        let obj = try await EvergreenAsync.fetchMetarecordMODS(id: holdTarget)
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

        let modsObj = try await EvergreenAsync.fetchRecordMODS(id: target)
        let record = MBRecord(mvrObj: modsObj)
        let mraObj = try await EvergreenAsync.fetchMRA(id: record.id)
        record.update(fromMraObj: mraObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=P done", log: log, type: .info, holdTarget)
    }

    func loadCopyHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=C start", log: log, type: .info, holdTarget)
        let acpObj = try await fetchACP(id: holdTarget)
        guard let callNumber = acpObj.getID("call_number") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to find call_number for copy hold")
        }

        let acnObj = try await fetchACN(id: callNumber)
        guard let id = acnObj.getID("record") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for copy hold")
        }

        let modsObj = try await EvergreenAsync.fetchRecordMODS(id: id)
        let record = MBRecord(mvrObj: modsObj)
        hold.setMetabibRecord(record)
        os_log("[hold] target=%d holdType=C done", log: log, type: .info, holdTarget)
    }

    func loadVolumeHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) async throws {
        os_log("[hold] target=%d holdType=V start", log: log, type: .info, holdTarget)
        let acnObj = try await fetchACN(id: holdTarget)
        guard let id = acnObj.getID("record") else {
            throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for volume hold")
        }

        let modsObj = try await EvergreenAsync.fetchRecordMODS(id: id)
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
        let param: JSONDictionary = [
            "record": targetId
        ]
        let req = Gateway.makeRequest(service: API.search, method: API.holdParts, args: [param], shouldCache: true)
        let parts = try await req.gatewayResponseAsync().asArray()
        return parts.map { XHoldPart(id: $0.getInt("id") ?? -1, label: $0.getString("label") ?? "Unknown part") }
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
        let obj = try await placeHoldImpl(account: account, targetId: targetId, withOptions: options)
        // ASSUMING that all variants of place hold failure are converted to errors with asObject
        // if not we need to fix it?
        print("obj: \(obj.dict)")
        if let _ = obj.getInt("result") {
            // case 1: result is an Int - hold successful
            print("true")
        } else if let resultObj = obj.getAny("result") as? OSRFObject,
            let eventObj = resultObj.getAny("last_event") as? OSRFObject
        {
            // case 2: result is an object with last_event - hold failed
            print("error: \(eventObj)")
        } else if let resultArray = obj.getAny("result") as? [OSRFObject],
            let eventObj = resultArray.first
        {
            // case 3: result is an array of ilsevent objects - hold failed
            print("error: \(eventObj)")
        } else {
            print("unexpected: \(String(describing: obj.dict))")
        }
        return true
    }

    private func placeHoldImpl(account: Account, targetId: Int, withOptions options: XHoldOptions) async throws -> OSRFObject {
        var complexParam: JSONDictionary = [
            "email_notify": options.notifyByEmail,
            "hold_type": options.holdType,
            "patronid": account.userID,
            "pickup_lib": options.pickupOrgId,
        ]
        if let phoneNumber = options.phoneNotify,
            !phoneNumber.isEmpty
        {
            complexParam["phone_notify"] = phoneNumber
        }
        if let smsNumber = options.smsNotify,
           !smsNumber.isEmpty,
           let carrierID = options.smsCarrierId
        {
            complexParam["sms_notify"] = smsNumber
            complexParam["sms_carrier"] = carrierID
        }
        if let date = options.expirationDate {
            complexParam["expire_time"] = OSRFObject.apiDateFormatter.string(from: date)
        }
        let method = options.useOverride ? API.holdTestAndCreateOverride : API.holdTestAndCreate
        let req = Gateway.makeRequest(service: API.circ, method: method, args: [account.authtoken, complexParam, [targetId]], shouldCache: false)
        return try await req.gatewayResponseAsync().asObject()
    }

    func updateHold(account: Account, holdId: Int, withOptions options: XHoldUpdateOptions) async throws -> Bool {
        let resp = try await updateHoldImpl(account: account, holdId: holdId, withOptions: options)
        if let _ = resp.str {
            // case 1: result is String - update successful
            print("ok")
        } else if let err = resp.error {
            print("error: \(err)")
            throw err
        } else {
            throw HemlockError.serverError("expected string, received \(resp.description)")
        }
        return true
    }

    private func updateHoldImpl(account: Account, holdId: Int, withOptions options: XHoldUpdateOptions) async throws -> GatewayResponse {
        var complexParam: JSONDictionary = [
            "id": holdId,
            "pickup_lib": options.pickupOrgId,
            "frozen": options.suspended,

        ]
        if let str = notifyPhoneNumber, !str.isEmpty {
            complexParam["phone_notify"] = str
        }
        if let str = notifySMSNumber, !str.isEmpty {
            complexParam["sms_notify"] = str
        }
        if let carrierID = smsCarrierID {
            complexParam["sms_carrier"] = carrierID
        }
        if let date = expirationDate {
            complexParam["expire_time"] = OSRFObject.apiDateFormatter.string(from: date)
        }
        if let date = thawDate {
            complexParam["thaw_date"] = OSRFObject.apiDateFormatter.string(from: date)
        }
        let req = Gateway.makeRequest(service: API.circ, method: API.holdUpdate, args: [authtoken, nil, complexParam], shouldCache: false)
        return try await req.gatewayResponseAsync()
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
