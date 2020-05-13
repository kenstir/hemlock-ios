//
//  AccountManager.swift
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
import Valet

// Manages usernames and passwords stored in the keychain
class AccountManager {
    
    let version = 1
    let valet: Valet
    var accountsBundle: JSONDictionary = [
        "last_username": nil,
        "accounts": nil
    ]
    var lastUsername: String? { return accountsBundle["last_username"] as? String }
    
    init(valet: Valet) {
        self.valet = valet
        load()
    }
    
    func load() {
        if let data = valet.object(forKey: "Accounts"),
            let jsonObject = decodeJSON(data)
        {
            accountsBundle = jsonObject
        }
    }
    
    func decodeJSON(_ data: Data) -> JSONDictionary? {
        if
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? JSONDictionary
        {
            return jsonObject
        } else {
            return nil
        }
    }
}
