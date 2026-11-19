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
    var displayName: String?
    var chooserLabel: String {
        if let dname = displayName, dname != username {
            return "\(username) (\(dname))"
        }
        return username
    }
    init(username: String, password: String, displayName: String? = nil) {
        self.username = username
        self.password = password
        self.displayName = displayName
    }
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
    var lastUsedCredential: Credential? {
        return bundle.credentials.first(where: { $0.username == bundle.lastUsername })
    }
    var numCredentials: Int {
        return bundle.credentials.count
    }

    init(valet: Valet) {
        self.valet = valet
        self.bundle = CredentialBundleV1(lastUsername: nil, credentials: [])
        loadFromStorage()
    }

    func loadFromStorage() {
        // handle V1 storage
        if let data = try? valet.object(forKey: CredentialManager.storageKeyV1),
            let bundle = try? JSONDecoder().decode(CredentialBundleV1.self, from: data) {
            self.bundle = bundle
            Logger.data.info("[creds] loaded \(bundle.credentials.count) V1 creds last=\(optName(bundle.lastUsername))")
            return
        }

        // handle legacy storage
        if let username = try? valet.string(forKey: CredentialManager.legacyUsernameKey),
            let password = try? valet.string(forKey: CredentialManager.legacyPasswordKey)
        {
            let credential = Credential(username: username, password: password)
            self.bundle = CredentialBundleV1(lastUsername: username, credentials: [credential])
            try? valet.removeObject(forKey: CredentialManager.legacyUsernameKey)
            try? valet.removeObject(forKey: CredentialManager.legacyPasswordKey)
            self.writeToStorage()
            let bundle = self.bundle
            Logger.data.info("[creds] loaded \(bundle.credentials.count) legacy creds last=\(optName(bundle.lastUsername))")
            return
        }

        Logger.data.info("[creds] no creds loaded")
    }

    func writeToStorage() {
        if let data = try? JSONEncoder().encode(bundle) {
            try? valet.setObject(data, forKey: CredentialManager.storageKeyV1)
            let bundle = self.bundle
            Logger.data.info("[creds] wrote \(bundle.credentials.count) V1 creds last=\(optName(bundle.lastUsername))")
        }
    }

    func add(credential: Credential) {
        Logger.data.info("[creds] add \(credential.username)")
        if let index = bundle.credentials.firstIndex(where: { $0.username == credential.username }) {
            bundle.credentials[index] = credential
            Logger.data.info("[creds] replaced \(credential.username)")
        } else {
            bundle.credentials.append(credential)
            sortCredentialsByName()
            Logger.data.info("[creds] added \(credential.username)")
        }
        bundle.lastUsername = credential.username
        writeToStorage()
    }
    
    func setActive(credential: Credential?) {
        if let username = credential?.username,
            let _ = bundle.credentials.firstIndex(where: { $0.username == username }) {
            bundle.lastUsername = username
        }
        Logger.data.info("[creds] setActive \(optName(credential?.username)) last=\(optName(self.bundle.lastUsername))")
    }

    func removeCredential(forUsername username: String?) {
        if let index = bundle.credentials.firstIndex(where: { $0.username == username }) {
            bundle.credentials.remove(at: index)
            if bundle.lastUsername == username {
                bundle.lastUsername = bundle.credentials.first?.username
            }
            Logger.data.info("[creds] removed \(optName(username)) last=\(optName(self.bundle.lastUsername))")
            writeToStorage()
        }
    }

    func clearAllCredentials() {
        bundle.credentials = []
        bundle.lastUsername = nil
        Logger.data.info("[creds] clear all")
        writeToStorage()
    }

    private func sortCredentialsByName() {
        bundle.credentials.sort(by: { $0.username < $1.username })
    }
}

/// returns username for use in logging
func optName(_ name: String?) -> String {
    return name ?? "(nil)"
}
