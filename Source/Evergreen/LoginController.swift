//
//  LoginController.swift
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
import Alamofire

class LoginController {
    var account: Account
    var nonce: String?
    
    init(for account: Account) {
        self.account = account
    }
    
    func login(completion: @escaping (_: GatewayResponse) -> Void) {
        account.authtoken = nil
        account.authtokenExpiryDate = nil
        let request = API.createRequest(service: API.auth, method: API.authInit, args: [account.username])
        request.responseData { response in
            print("response: \(response.description)")
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                let errorMessage = response.description 
                completion(GatewayResponse.makeError(errorMessage))
                return
            }
            debugPrint(data)
            let resp = GatewayResponse(data)
            guard let nonce = resp.stringResult else {
                completion(GatewayResponse.makeError("unexpected response to login"))
                return
            }
            self.nonce = nonce
            
            self.loginComplete(completion: completion)
        }
    }
    
    func loginComplete(completion: @escaping (_: GatewayResponse) -> Void) {
        let md5password = md5(self.nonce! + md5(self.account.password))
        let objectParam = ["type": "opac",
                          "username": self.account.username,
                          "password": md5password]
        let request = API.createRequest(service: API.auth, method: API.authComplete, args: [objectParam])
        print("request:  \(request.description)")
        request.responseData { response in
            print("response: \(response.description)")
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                let errorMessage = response.description
                completion(GatewayResponse.makeError(errorMessage))
                return
            }
            debugPrint(data)
            let resp = GatewayResponse(data)
            guard let obj = resp.objectResult,
                let textcode = obj["textcode"] as? String,
                let desc = obj["desc"] as? String else
            {
                completion(GatewayResponse.makeError("Unexpected response to login"))
                return
            }
            guard textcode == "SUCCESS" else {
                completion(GatewayResponse.makeError(desc))
                return
            }
            guard let payload = obj["payload"] as? [String: Any],
                let authtoken = payload["authtoken"] as? String,
                let authtime = payload["authtime"] as? Int else
            {
                completion(GatewayResponse.makeError("Unexpected response to login"))
                return
            }
            
            self.account.authtoken = authtoken
            debugPrint(self.account)
            self.account.authtokenExpiryDate = Date(timeIntervalSinceNow: TimeInterval(authtime))
            completion(resp)
        }
    }
    
    static func getSession(_ account: Account, completion: @escaping (_: GatewayResponse) -> Void) {
        guard let authtoken = account.authtoken else {
            completion(GatewayResponse.makeError("No auth token"))
            return
        }
        let request = API.createRequest(service: API.auth, method: API.authGetSession, args: [authtoken])
        print("request:  \(request.description)")
        request.responseData { response in
            print("response: \(response.description)")
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                let errorMessage = response.description
                completion(GatewayResponse.makeError(errorMessage))
                return
            }
            debugPrint(data)
            let resp = GatewayResponse(data)
            completion(resp)
        }
    }
}
