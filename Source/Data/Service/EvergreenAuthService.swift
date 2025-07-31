//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import Foundation
import os.log

class EvergreenAuthService : XAuthService {
    func fetchAuthToken(credential: Credential) async throws -> String {
        let req = Gateway.makeRequest(service: API.auth, method: API.authInit, args: [credential.username], shouldCache: false)
        let resp: GatewayResponse = try await req.gatewayResponseAsync()
        guard let nonce = resp.str else {
            throw HemlockError.serverError("expected string")
        }
        let md5password = md5(nonce + md5(credential.password))
        let objectParam = [
            "type": "persist",
            "username": credential.username,
            "password": md5password
        ]
        let req2 = Gateway.makeRequest(service: API.auth, method: API.authComplete, args: [objectParam], shouldCache: false)
        return try await req2.gatewayAuthtokenResponseAsync()
    }

    static func fetchSession(authtoken: String) async throws -> OSRFObject {
        let req = Gateway.makeRequest(service: API.auth, method: API.authGetSession, args: [authtoken], shouldCache: false)
        return try await req.gatewayObjectResponseAsync()
    }
}
