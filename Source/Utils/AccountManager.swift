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

struct StoredAccountBundle: Codable {
    var lastUsername: String?
    var accounts: [StoredAccount]
}

// Manages usernames and passwords stored in the keychain
class AccountManager {
    
    static let storageKey = "Accounts"
    static let storageVersion = 1

    private let valet: Valet
    private var bundle: StoredAccountBundle
    var accounts: [StoredAccount] {
        return bundle.accounts
    }
    var lastAccount: StoredAccount? {
        return bundle.accounts.first(where: { $0.username == bundle.lastUsername })
    }
    
    init(valet: Valet) {
        self.valet = valet
        self.bundle = StoredAccountBundle(lastUsername: nil, accounts: [])
        loadFromStorage()
    }
    
    func loadFromStorage() {
        if let data = valet.object(forKey: AccountManager.storageKey),
            let bundle = try? JSONDecoder().decode(StoredAccountBundle.self, from: data) {
            self.bundle = bundle
        }
    }
    
    func writeToStorage() {
        if let data = try? JSONEncoder().encode(bundle) {
            valet.set(object: data, forKey: AccountManager.storageKey)
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
    
    func remove(username: String) {
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
