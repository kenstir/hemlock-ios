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
    static let log = OSLog(subsystem: App.config.logSubsystem, category: "pcrud")

    static func fetchSMSCarriers() -> Promise<Void> {
        if carriersLoaded {
            return Promise<Void>()
        }
        let options: [String: Any] = ["active": 1]
        let req = Gateway.makeRequest(service: API.pcrud, method: API.searchSMSCarriers, args: [API.anonymousAuthToken, options])
        let promise = req.gatewayArrayResponse().done { array in
            try SMSCarrier.loadSMSCarriers(fromArray: array)
            carriersLoaded = true
        }
        return promise
    }

    static func fetchSearchFormat(authtoken: String, forRecord record: MBRecord) -> Promise<Void> {
        os_log("fetchSearchFormat id=%d start", log: PCRUDService.log, type: .info, record.id)
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymousAuthToken, record.id])
        let promise = req.gatewayObjectResponse().done { obj in
            record.searchFormat = Format.getSearchFormat(fromMRAObject: obj)
            os_log("fetchSearchFormat id=%d done format=%@ title=%@", log: PCRUDService.log, type: .info, record.id, record.searchFormat ?? "?", record.title)
        }
        return promise
    }
}
