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

struct StoredAccount: Equatable {
    let username: String
    let password: String?
}

// Manages usernames and passwords stored in the keychain
class AccountManager {
    
    static let storageKey = "Accounts"
    static let storageVersion = 1

    private let valet: Valet
    private var lastUsername: String? = nil
    var accounts: [StoredAccount] = []
    var lastAccount: StoredAccount? {
        return accounts.first(where: { $0.username == lastUsername })
    }
    
    init(valet: Valet) {
        self.valet = valet
        loadFromStorage()
    }
    
    func loadFromStorage() {
        guard let data = valet.object(forKey: AccountManager.storageKey),
            let jsonObject = JSONUtils.parseObject(fromData: data) else {
            return
        }
        lastUsername = jsonObject["last_username"] as? String
        guard let accountObjects = jsonObject["accounts"] as? [JSONDictionary] else {
            return
        }
        for accountObject in accountObjects {
            if let username = accountObject["username"] as? String,
                let password = accountObject["password"] as? String
            {
                accounts.append(StoredAccount(username: username, password: password))
            }
        }
    }
    
}
