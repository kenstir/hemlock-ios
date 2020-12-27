//
//  GatewayResponse.swift
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

//TODO: fold GatewayError into HemlockError
public enum GatewayError: Error {
    case event(ilsevent: Int, textcode: String, desc: String, failpart: String?)
    case failure(String)
}
extension GatewayError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .event(_, let textcode, let desc, let failpart):
            let messageOverrides = [
                "HIGH_LEVEL_HOLD_HAS_NO_COPIES": "The selected item is not holdable.  Call your local library with any questions."]
            if let msg = MessageMap.eventMessageMap[textcode] { return msg }
            if let failPartKey = failpart,
                let msg = MessageMap.failPartMessageMap[failPartKey] { return msg }
            if let msg = messageOverrides[textcode] { return msg }
            return desc
        case .failure(let reason):
            return reason
        }
    }
}

enum GatewayResponseType {
    case object
    case array
    case string
    case empty
    case unknown
    case error
}

struct GatewayResponse {
    //MARK: - Properties

    var type: GatewayResponseType
    var error: GatewayError?

    // a field for each GatewayResultType; I'm sure there's a better way
    var stringResult: String?
    var objectResult: OSRFObject?
    var arrayResult: [OSRFObject]?
    var str: String? { return stringResult }
    var obj: OSRFObject? { return objectResult }
    var array: [OSRFObject]? { return arrayResult }
    
    var payload: Any? // raw payload

    var failed: Bool {
        return type == .error
    }
    var errorMessage: String {
        guard let error = self.error else {
            return "no error"
        }
        return error.localizedDescription
    }
    var description: String {
        switch type {
        case .object:
            return "object"
        case .array:
            return "array"
        case .string:
            return "string"
        case .empty:
            return "empty"
        case .unknown:
            return "unknown"
        case .error:
            return "error"
        }
    }
    
    //MARK: - Lifecycle
    
    init() {
        type = .error
        error = .failure("unintialized")
    }
    
    init(_ jsonString: String) {
        self.init()
        //os_log("resp.str: %@", log: Gateway.log, type: .info, jsonString)
        guard let data = jsonString.data(using: .utf8) else {
            error = .failure("Unable to encode as utf8: \(jsonString)")
            return
        }
        self.init(data)
    }
    
    static func errorMessage(forInvalidJSON str: String) -> String {
        if str.contains("canceling statement due to user request") {
            return "Timeout; the request took too long to complete and the server killed it"
        }
        return "Internal Server Error; the server response is not JSON"
    }

    init(_ data: Data) {
        self.init()
        let wire_str = String(data: data, encoding: .utf8) ?? "(nil)"
        guard let json = decodeJSON(data) else {
            os_log("resp.json: decode_error", log: Gateway.log, type: .info)
            let errorMessage = GatewayResponse.errorMessage(forInvalidJSON: wire_str)
            error = .failure(errorMessage)
            return
        }
        //os_log("resp.json: %@", log: Gateway.log, type: .info, json)

        guard let status = json["status"] as? Int else {
            error = .failure("Internal Server Error; the server response has no status")
            return
        }
        if status != 200 {
            error = .failure("Request failed with status \(status)")
            return
        }

        // payload is always an array,
        // usually an array of one json object,
        // but in the cases of authInit it is an array of one string
        guard let payload = json["payload"] as? [Any] else {
            error = .failure("Internal Server Error; response has payload")
            return
        }
        self.payload = payload
        if payload.count == 0 {
            type = .empty
        } else if let val = payload.first as? JSONDictionary {
            var obj: OSRFObject?
            do {
                try obj = decodeObject(val)
            } catch {
                self.error = .failure("Error decoding OSRF object: " + error.localizedDescription)
                return
            }
            if let eventError = parseEvent(fromObj: obj) {
                self.error = eventError
                return
            }
            type = .object
            objectResult = obj
        } else if let val = payload.first as? [JSONDictionary] {
            do {
                try arrayResult = decodeArray(val)
            } catch {
                self.error = .failure("Error decoding OSRF array: " + error.localizedDescription)
                return
            }
            if let obj = arrayResult?.first,
                let eventError = parseEvent(fromObj: obj) {
                self.error = eventError
                return
            }
            type = .array
        } else if let val = payload.first as? String {
            type = .string
            stringResult = val
        } else {
            type = .unknown
            return
        }
        error = nil
    }
    
    // MARK: - Functions

    func decodeJSON(_ data: Data) -> [String: Any]? {
        if
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any]
        {
            return jsonObject
        } else {
            return nil
        }
    }
    
    func decodeObject(_ jsonObject: [String: Any?]) throws -> OSRFObject {
        let obj = try OSRFCoder.decode(fromDictionary: jsonObject)
        //os_log("resp.obj: %@", log: Gateway.log, type: .info, obj.dict)
        return obj
    }
    
    func decodeArray(_ jsonArray: [[String: Any?]]) throws -> [OSRFObject] {
        return try OSRFCoder.decode(fromArray: jsonArray)
    }
    
    func parseEvent(fromObj obj: OSRFObject?) -> GatewayError? {
        // case 1: obj is an event
        if let ilsevent = obj?.getDouble("ilsevent"),
            ilsevent != 0,
            let textcode = obj?.getString("textcode"),
            let desc = obj?.getString("desc")
        {
            let failpart = obj?.getObject("payload")?.getString("fail_part")
            return .event(ilsevent: Int(ilsevent), textcode: textcode, desc: desc, failpart: failpart)
        }

        // case 2: obj has a last_event, or a result with a last_event
        if let lastEvent = obj?.getObject("result")?.getObject("last_event") ?? obj?.getObject("last_event")            
        {
            return parseEvent(fromObj: lastEvent)
        }

        // case 3: obj has a result that is an array of events
        if let array = obj?.getAny("result") as? [OSRFObject],
            let firstObj = array.first
        {
            return parseEvent(fromObj: firstObj)
        }

        return nil
    }

    static func makeError(_ reason: String) -> GatewayResponse {
        var resp = GatewayResponse()
        resp.error = .failure(reason)
        return resp
    }
}
