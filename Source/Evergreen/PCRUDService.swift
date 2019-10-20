//
//  PCRUDService.swift
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
import PromiseKit
import os.log

class PCRUDService {
    static var carriersLoaded = false
    static var ccvmLoaded = false
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "pcrud")
    
    static func fetchCodedValueMaps() -> Promise<Void> {
        if ccvmLoaded {
            return Promise<Void>()
        }
        let query: [String: Any] = ["ctype": ["icon_format", "search_format"]]
        let req = Gateway.makeRequest(service: API.pcrud, method: API.searchCCVM, args: [API.anonymousAuthToken, query])
        let promise = req.gatewayArrayResponse().done { array in
            CodedValueMap.load(fromArray: array)
            ccvmLoaded = true
        }
        return promise
    }

    static func fetchSMSCarriers() -> Promise<Void> {
        if carriersLoaded {
            return Promise<Void>()
        }
        let options: [String: Any] = ["active": 1]
        let req = Gateway.makeRequest(service: API.pcrud, method: API.searchSMSCarriers, args: [API.anonymousAuthToken, options])
        let promise = req.gatewayArrayResponse().done { array in
            SMSCarrier.loadSMSCarriers(fromArray: array)
            carriersLoaded = true
        }
        return promise
    }

    static func fetchMRA(authtoken: String, forRecord record: MBRecord) -> Promise<Void> {
        os_log("fetchMRA id=%d start", log: PCRUDService.log, type: .info, record.id)
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymousAuthToken, record.id])
        let promise = req.gatewayObjectResponse().done { obj in
            record.attrs = RecordAttributes.parseAttributes(fromMRAObject: obj)
            os_log("fetchMRA id=%d done format=%@ title=%@", log: PCRUDService.log, type: .info, record.id, record.iconFormatLabel ?? "", record.title)
        }
        return promise
    }
    
    static func fetchMARC(forRecord record: MBRecord) -> Promise<Void> {
        os_log("fetchMARC id=%d start", log: PCRUDService.log, type: .info, record.id)
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveBRE, args: [API.anonymousAuthToken, record.id])
        let promise = req.gatewayObjectResponse().done { obj in
            guard let marcXML = obj.getString("marc") else {
                throw HemlockError.unexpectedNetworkResponse("no marc for record \(record.id)")
            }
            guard let data = marcXML.data(using: .utf8) else {
                throw HemlockError.unexpectedNetworkResponse("failed to parse marc for record \(record.id)")
            }
            let parser = MARCXMLParser(data: data)
            record.marcRecord = try parser.parse()
            os_log("fetchMARC id=%d done", log: PCRUDService.log, type: .info, record.id)
        }
        return promise
    }
}
