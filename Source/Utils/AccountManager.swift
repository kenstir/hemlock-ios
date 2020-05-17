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

struct StoredAccount: Codable, Equatable {
    let username: String
    let password: String?
}

struct StoredAccountBundleV1: Codable {
    var lastUsername: String?
    var accounts: [StoredAccount]
}

// Manages usernames and passwords stored in the keychain
//
// Keychain Storage
// ----------------
// We store accounts in Valet as a StoredAccountBundleV1, and we rewrite
// the storage every time something changes.
//
// The OG app stored a single account in Valet keys "username" and "password";
// if we find those keys during construction, we rewrite the bundle in the V1
// format and remove the old keys.
//
// If and when we need a different storage schema, the plan is to define
// a V2 bundle stored under a V2 key, and convert V1 storage to it during
// construction.
//
class AccountManager {
    
    static let storageKeyV1 = "Accounts"
    static let legacyUsernameKey = "username"
    static let legacyPasswordKey = "password"

    private let valet: Valet
    private var bundle: StoredAccountBundleV1
    var accounts: [StoredAccount] {
        return bundle.accounts
    }
    var lastAccount: StoredAccount? {
        return bundle.accounts.first(where: { $0.username == bundle.lastUsername })
    }
    
    init(valet: Valet) {
        self.valet = valet
        self.bundle = StoredAccountBundleV1(lastUsername: nil, accounts: [])
        loadFromStorage()
    }
    
    func loadFromStorage() {
        // handle V1 storage
        if let data = valet.object(forKey: AccountManager.storageKeyV1),
            let bundle = try? JSONDecoder().decode(StoredAccountBundleV1.self, from: data) {
            self.bundle = bundle
            return
        }
        
        // handle legacy storage
        if let username = valet.string(forKey: AccountManager.legacyUsernameKey),
            let password = valet.string(forKey: AccountManager.legacyPasswordKey)
        {
            let account = StoredAccount(username: username, password: password)
            self.bundle = StoredAccountBundleV1(lastUsername: username, accounts: [account])
            valet.removeObject(forKey: AccountManager.legacyUsernameKey)
            valet.removeObject(forKey: AccountManager.legacyPasswordKey)
            self.writeToStorage()
            return
        }
    }
    
    func writeToStorage() {
        if let data = try? JSONEncoder().encode(bundle) {
            valet.set(object: data, forKey: AccountManager.storageKeyV1)
        }
    }

    func add(account: StoredAccount) {
        if let index = bundle.accounts.firstIndex(where: { $0.username == account.username }) {
            bundle.accounts[index] = account
        } else {
            bundle.accounts.append(account)
            sortAccounts()
        }
        bundle.lastUsername = account.username
        writeToStorage()
    }
    
    func setActive(account: StoredAccount?) {
        if let username = account?.username,
            let _ = bundle.accounts.firstIndex(where: { $0.username == username }) {
            bundle.lastUsername = username
        } else {
            bundle.lastUsername = nil
        }
    }

    func remove(username: String?) {
        if let index = bundle.accounts.firstIndex(where: { $0.username == username }) {
            bundle.accounts.remove(at: index)
            if bundle.lastUsername == username {
                bundle.lastUsername = bundle.accounts.first?.username
            }
            writeToStorage()
        }
    }
    
    private func sortAccounts() {
        bundle.accounts.sort(by: { $0.username < $1.username })
    }
}
