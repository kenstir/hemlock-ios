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
    let account: Account
    var nonce: String?
    
    init(username: String, password: String) {
        account = Account(username: username, password: password)
    }
    
    func login(completion: @escaping (_: Account, _: GatewayResponse) -> Void) {
        let request = API.createRequest(service: API.auth, method: API.authInit, args: [account.username])
        print("request:  \(request.description)")
        if let httpBody = request.request?.httpBody {
            print("body:      \(httpBody)")
        }
        request.responseData { response in
            if let httpBody = request.request?.httpBody {
                print("body:      \(httpBody)")
            }
            print("response: \(response.description)")
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                let errorMessage = response.description 
                completion(self.account, GatewayResponse.makeError(errorMessage))
                return
            }
            debugPrint(data)
            let resp = GatewayResponse(data)
            guard let nonce = resp.stringResult else {
                completion(self.account, GatewayResponse.makeError("unexpected response to login"))
                return
            }
            self.nonce = nonce
            
            self.loginComplete(completion: completion)
        }
    }
    
    func loginComplete(completion: @escaping (_: Account, _: GatewayResponse) -> Void) {
        let md5password = md5(self.nonce! + self.account.password)
        let osrfObject = ["type": "opac", "username": self.account.username, "password": md5password]
        let request = API.createRequest(service: API.auth, method: API.authComplete, args: [osrfObject])
        print("request:  \(request.description)")
        request.responseData { response in
            if let httpBody = request.request?.httpBody {
                print("body:      \(httpBody)")
            }
            print("response: \(response.description)")
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                let errorMessage = response.description
                completion(self.account, GatewayResponse.makeError(errorMessage))
                return
            }
            debugPrint(data)
            let resp = GatewayResponse(data)
            completion(self.account, resp)
        }
    }
}
