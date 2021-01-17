//
//  AuthService.swift
//
//  Copyright (C) 2020 Kenneth H. Cox
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
import os.log

class AuthService {
    static func fetchAuthToken(credential: Credential) -> Promise<(String)> {
        let req = Gateway.makeRequest(service: API.auth, method: API.authInit, args: [credential.username], shouldCache: false)
        let promise = req.gatewayResponse().then { (resp: GatewayResponse) -> Promise<(String)> in
            print("resp: \(resp)")
            guard let nonce = resp.str else {
                throw HemlockError.serverError("expected string")
            }
            let md5password = md5(nonce + md5(credential.password))
            let objectParam = ["type": "persist",
                               "username": credential.username,
                               "password": md5password]
            let req = Gateway.makeRequest(service: API.auth, method: API.authComplete, args: [objectParam], shouldCache: false)
            return req.gatewayAuthtokenResponse()
        }
        return promise
    }
    
    static func fetchSession(authtoken: String) -> Promise<(OSRFObject)> {
        let req = Gateway.makeRequest(service: API.auth, method: API.authGetSession, args: [authtoken], shouldCache: false)
        return req.gatewayObjectResponse()
    }

    /*
    static func makeStringPromise(_ str: String) -> Promise<(String)> {
        let promise = Promise<(String)>() { seal in
            seal.fulfill(str)
        }
        return promise
    }
    */
}
