//
//  CircService.swift
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
import PMKAlamofire

class CircService {
    static func renew(authtoken: String, userID: Int, targetCopy: Int) -> Promise<OSRFObject> {
        let complexParam: [String: Int] = [
            "patron": userID,
            "copyid": targetCopy,
            "opac_renewal": 1
        ]
        let req = Gateway.makeRequest(service: API.circ, method: API.renew, args: [authtoken, complexParam])
        return req.gatewayObjectResponse()
    }
    
    static func placeHold(authtoken: String, userID: Int, recordID: Int, pickupOrgID: Int, notifyByEmail: Bool, notifyPhoneNumber: String?, notifySMSNumber: String?, smsCarrierID: Int?) -> Promise<OSRFObject> {
        var complexParam: JSONDictionary = [
            "email_notify": notifyByEmail,
            "hold_type": "T", //Title
            "patronid": userID,
            "pickup_lib": pickupOrgID,
        ]
        if let phoneNumber = notifyPhoneNumber {
            complexParam["phone_notify"] = phoneNumber
        }
        if let smsNumber = notifySMSNumber,
            smsNumber.count > 0,
            let carrierID = smsCarrierID
        {
            complexParam["sms_notify"] = smsNumber
            complexParam["sms_carrier"] = carrierID
        }
        let req = Gateway.makeRequest(service: API.circ, method: API.holdTestAndCreate, args: [authtoken, complexParam, [recordID]])
        return req.gatewayObjectResponse()
    }
    
    static func cancelHold(authtoken: String, holdID: Int) -> Promise<(resp: GatewayResponse, pmkresp: PMKAlamofireDataResponse)> {
        let req = Gateway.makeRequest(service: API.circ, method: API.holdCancel, args: [authtoken, holdID])
        return req.gatewayResponse()
    }
}
