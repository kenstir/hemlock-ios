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
    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "pcrud")

    static func fetchMRA(forRecord record: MBRecord) -> Promise<Void> {
//        os_log("fetchMRA id=%d start", log: PCRUDService.log, type: .info, record.id)
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymousAuthToken, record.id], shouldCache: true)
        let promise = req.gatewayOptionalObjectResponse().done { obj in
            record.update(fromMraObj: obj)
//            os_log("fetchMRA id=%d done format=%@ title=%@", log: PCRUDService.log, type: .info, record.id, record.iconFormatLabel, record.title)
        }
        return promise
    }

    static func fetchMARC(forRecord record: MBRecord) -> Promise<Void> {
        os_log("fetchMARC id=%d start", log: PCRUDService.log, type: .info, record.id)
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveBRE, args: [API.anonymousAuthToken, record.id], shouldCache: true)
        let promise = req.gatewayObjectResponse().done { obj in
            record.update(fromBreObj: obj)
        }
        return promise
    }
}
