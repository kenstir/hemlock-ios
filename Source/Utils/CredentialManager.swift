//
//  CredentialManager.swift
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
import os.log

struct Credential: Codable, Equatable {
    let username: String
    let password: String
}

struct CredentialBundleV1: Codable {
    var lastUsername: String?
    var credentials: [Credential]
}

// Manages usernames and passwords stored in the keychain
//
// Keychain Storage
// ----------------
// We store accounts in Valet as a CredentialBundleV1, and we rewrite
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
class CredentialManager {
    
    static let storageKeyV1 = "Accounts"
    static let legacyUsernameKey = "username"
    static let legacyPasswordKey = "password"

    private let valet: Valet
    private var bundle: CredentialBundleV1
    var credentials: [Credential] {
        return bundle.credentials
    }
    var lastAccount: Credential? {
        return bundle.credentials.first(where: { $0.username == bundle.lastUsername })
    }
    
    init(valet: Valet) {
        self.valet = valet
        self.bundle = CredentialBundleV1(lastUsername: nil, credentials: [])
        loadFromStorage()
    }
    
    func loadFromStorage() {
        // handle V1 storage
        if let data = valet.object(forKey: CredentialManager.storageKeyV1),
            let bundle = try? JSONDecoder().decode(CredentialBundleV1.self, from: data) {
            self.bundle = bundle
            os_log("loaded %d V1 creds lastUsername %@", bundle.credentials.count, bundle.lastUsername ?? "(nil)")
            return
        }
        
        // handle legacy storage
        if let username = valet.string(forKey: CredentialManager.legacyUsernameKey),
            let password = valet.string(forKey: CredentialManager.legacyPasswordKey)
        {
            let account = Credential(username: username, password: password)
            self.bundle = CredentialBundleV1(lastUsername: username, credentials: [account])
            valet.removeObject(forKey: CredentialManager.legacyUsernameKey)
            valet.removeObject(forKey: CredentialManager.legacyPasswordKey)
            self.writeToStorage()
            os_log("loaded %d legacy creds lastUsername %@", bundle.credentials.count, bundle.lastUsername ?? "(nil)")
            return
        }
        
        os_log("no creds loaded")
    }
    
    func writeToStorage() {
        if let data = try? JSONEncoder().encode(bundle) {
            valet.set(object: data, forKey: CredentialManager.storageKeyV1)
            os_log("wrote %d V1 creds lastUsername %@", bundle.credentials.count, bundle.lastUsername ?? "(nil)")
        }
    }

    func add(credential: Credential) {
        if let index = bundle.credentials.firstIndex(where: { $0.username == credential.username }) {
            bundle.credentials[index] = credential
            os_log("add existing creds username %@", credential.username)
        } else {
            bundle.credentials.append(credential)
            sortCredentialsByName()
            os_log("add new creds username %@", credential.username)
        }
        bundle.lastUsername = credential.username
        writeToStorage()
    }
    
    func setActive(credential: Credential?) {
        if let username = credential?.username,
            let _ = bundle.credentials.firstIndex(where: { $0.username == username }) {
            bundle.lastUsername = username
        } else {
            bundle.lastUsername = nil
        }
        os_log("setActive creds username %@ lastUsername %@", credential?.username ?? "", bundle.lastUsername ?? "")
    }

    func removeCredential(forUsername username: String?) {
        if let index = bundle.credentials.firstIndex(where: { $0.username == username }) {
            bundle.credentials.remove(at: index)
            if bundle.lastUsername == username {
                bundle.lastUsername = bundle.credentials.first?.username
            }
            os_log("remove creds username %@ lastUsername %@", username ?? "", bundle.lastUsername ?? "")
            writeToStorage()
        }
    }
    
    private func sortCredentialsByName() {
        bundle.credentials.sort(by: { $0.username < $1.username })
    }
}
