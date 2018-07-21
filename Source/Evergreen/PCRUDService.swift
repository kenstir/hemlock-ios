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

class PCRUDService {
    static var carriersLoaded = false
    
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
}
