 //  Account.swift
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

class Account {
    let username: String
    var password: String
    var authtoken: String?
    var authtokenExpiryDate: Date?
    var userID: Int?
    
    init(_ username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func loadFromAuthResponse(_ fromObj: OSRFObject?) throws -> Void {
        guard let obj = fromObj else {
            //todo: add analytics
            throw HemlockError.unexpectedNetworkResponse("Unexpected response to login")
        }
        
        guard let payload = obj.getObject("payload"),
            let authtoken = payload.getString("authtoken"),
            let authtime = payload.getInt("authtime") else
        {
            var msg = "Login failed"
            if let desc = obj.getString("desc") {
                msg = desc
            }
            throw HemlockError.loginFailed(msg)
        }

        self.authtoken = authtoken
        self.authtokenExpiryDate = Date(timeIntervalSinceNow: TimeInterval(authtime))
    }
    
    func clearCredentials() -> Void {
        self.password = ""
        self.authtoken = nil
        self.authtokenExpiryDate = nil
        self.userID = nil
    }
}
