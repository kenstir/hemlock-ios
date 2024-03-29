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
        let req = Gateway.makeRequest(service: API.circ, method: API.renew, args: [authtoken, complexParam], shouldCache: false)
        return req.gatewayObjectResponse()
    }
    
    // This returns a Promise<GatewayResponse> and not Promise<OSRFObject>
    // because we don't want to reject the promise chain if a title hold is not possible.
    static func titleHoldIsPossible(authtoken: String, userID: Int, targetID: Int, pickupOrgID: Int) -> Promise<GatewayResponse> {
        let complexParam: JSONDictionary = [
            "patronid": userID,
            "pickup_lib": pickupOrgID,
            "hold_type": API.holdTypeTitle,
            "titleid": targetID,
        ]
        let req = Gateway.makeRequest(service: API.circ, method: API.titleHoldIsPossible, args: [authtoken, complexParam], shouldCache: false)
        return req.gatewayResponse()
    }
    
    static func placeHold(authtoken: String, userID: Int, holdType: String, targetID: Int, pickupOrgID: Int, notifyByEmail: Bool, notifyPhoneNumber: String?, notifySMSNumber: String?, smsCarrierID: Int?, expirationDate: Date?, useOverride: Bool) -> Promise<OSRFObject> {
        var complexParam: JSONDictionary = [
            "email_notify": notifyByEmail,
            "hold_type": holdType,
            "patronid": userID,
            "pickup_lib": pickupOrgID,
        ]
        if let phoneNumber = notifyPhoneNumber,
            !phoneNumber.isEmpty
        {
            complexParam["phone_notify"] = phoneNumber
        }
        if let smsNumber = notifySMSNumber,
            !smsNumber.isEmpty,
            let carrierID = smsCarrierID
        {
            complexParam["sms_notify"] = smsNumber
            complexParam["sms_carrier"] = carrierID
        }
        if let date = expirationDate {
            complexParam["expire_time"] = OSRFObject.apiDateFormatter.string(from: date)
        }
        let method = useOverride ? API.holdTestAndCreateOverride : API.holdTestAndCreate
        let req = Gateway.makeRequest(service: API.circ, method: method, args: [authtoken, complexParam, [targetID]], shouldCache: false)
        return req.gatewayObjectResponse()
    }

    static func updateHold(authtoken: String, holdRecord: HoldRecord, pickupOrgID: Int, notifyByEmail: Bool, notifyPhoneNumber: String?, notifySMSNumber: String?, smsCarrierID: Int?, expirationDate: Date?, suspendHold: Bool, thawDate: Date?) -> Promise<(GatewayResponse)> {
        var complexParam: JSONDictionary = [
            "id": holdRecord.id,
            "email_notify": notifyByEmail,
            "pickup_lib": pickupOrgID,
            "frozen": suspendHold,
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
        return req.gatewayResponse()
    }

    static func cancelHold(authtoken: String, holdID: Int) -> Promise<(GatewayResponse)> {
        let note = "Cancelled by mobile app"
        let req = Gateway.makeRequest(service: API.circ, method: API.holdCancel, args: [authtoken, holdID, nil, note], shouldCache: false)
        return req.gatewayResponse()
    }
}
