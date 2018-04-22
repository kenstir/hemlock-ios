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
        debugPrint(request)
/*
        request.responseJSON { response in
            guard let json = response.result.value else
            {
                completion(self.account, GatewayResponse.makeError())
                return
            }
            let resp = GatewayResponse(json)
            guard let self.nonce = resp.payloadString else {
                completion(self.account, GatewayResponse.makeError())
            }
        }
 */
        completion(self.account, GatewayResponse.makeError("EFAIL"))
    }
}
