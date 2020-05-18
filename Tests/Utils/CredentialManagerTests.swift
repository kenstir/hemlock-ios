//
//  CredentialManagerTests.swift
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

import XCTest
import Valet
@testable import Hemlock

class CredentialManagerTests: XCTestCase {
    
    let valet = Valet.valet(with: Identifier(nonEmpty: "HemlockTests")!, accessibility: .whenUnlockedThisDeviceOnly)
    let alice = Credential(username: "alice", password: "aliceisgreat")
    let bob = Credential(username: "bob", password: "bobiscool")

    override func setUp() {
        // cleanup any leftovers from prior runs
        valet.removeAllObjects()
    }

    func test_load_empty() {
        let cm = CredentialManager(valet: valet)
        XCTAssertNil(cm.lastUsedCredential)
        XCTAssertEqual(cm.credentials.count, 0)
    }
    
    func test_load_oneAccount() {
        let str = """
            {
              "lastUsername": "alice",
              "credentials": [
                {"username": "alice", "password": "*"}
              ]
            }
            """
        let data = str.data(using: .utf8)!
        valet.set(object: data, forKey: CredentialManager.storageKeyV1)
        
        let cm = CredentialManager(valet: valet)
        XCTAssertEqual(cm.lastUsedCredential, Credential(username: "alice", password: "*"))
        XCTAssertEqual(cm.credentials.count, 1)
        XCTAssertEqual(cm.credentials.first?.username, "alice")
        XCTAssertEqual(cm.credentials.first?.password, "*")
    }
    
    func test_load_multipleAccounts() {
        let str = """
            {
              "lastUsername": "bob",
              "credentials": [
                {"username": "alice", "password": "*a"},
                {"username": "bob", "password": "*b"},
                {"username": "charlie", "password": "*c"}
              ]
            }
            """
        
        guard let data = str.data(using: .utf8) else {
            XCTFail()
            return
        }
        valet.set(object: data, forKey: CredentialManager.storageKeyV1)
        
        let cm = CredentialManager(valet: valet)
        XCTAssertEqual(cm.lastUsedCredential, Credential(username: "bob", password: "*b"))
        XCTAssertEqual(cm.credentials.count, 3)
        XCTAssertEqual(cm.credentials[0], Credential(username: "alice", password: "*a"))
        XCTAssertEqual(cm.credentials[1], Credential(username: "bob", password: "*b"))
        XCTAssertEqual(cm.credentials[2], Credential(username: "charlie", password: "*c"))
    }
        
    func test_loadLegacyAccount() {
        valet.set(string: alice.username, forKey: CredentialManager.legacyUsernameKey)
        valet.set(string: alice.password, forKey: CredentialManager.legacyPasswordKey)
        
        let cm = CredentialManager(valet: valet)
        XCTAssertEqual(cm.credentials.count, 1)
        XCTAssertEqual(cm.credentials.first, alice)
        XCTAssertFalse(valet.containsObject(forKey: CredentialManager.legacyUsernameKey))
        XCTAssertFalse(valet.containsObject(forKey: CredentialManager.legacyPasswordKey))
        XCTAssertTrue(valet.containsObject(forKey: CredentialManager.storageKeyV1))
    }
    
    // Test that adding and removing works; construce CredentialManager multiple
    // times to test that state is properly saved to storage
    func test_addAndRemove() {
        var cm: CredentialManager
            
        // add bob
        cm = CredentialManager(valet: valet)
        cm.add(credential: bob)
        XCTAssertEqual(cm.credentials.count, 1)
        XCTAssertEqual(cm.credentials.first, bob)
        XCTAssertEqual(cm.lastUsedCredential, bob)

        // test restored state then add alice
        cm = CredentialManager(valet: valet)
        XCTAssertEqual(cm.credentials.count, 1)
        XCTAssertEqual(cm.credentials.first, bob)
        XCTAssertEqual(cm.lastUsedCredential, bob)
        cm.add(credential: alice)
        XCTAssertEqual(cm.lastUsedCredential, alice)

        // test restored state then remove alice
        cm = CredentialManager(valet: valet)
        XCTAssertEqual(cm.credentials.count, 2)
        XCTAssertEqual(cm.credentials.first, alice)
        cm.removeCredential(forUsername: alice.username)
        XCTAssertEqual(cm.lastUsedCredential, bob)

        // test restored state then remove bob
        cm = CredentialManager(valet: valet)
        XCTAssertEqual(cm.credentials.count, 1)
        XCTAssertEqual(cm.credentials.first, bob)
        cm.removeCredential(forUsername: bob.username)
        XCTAssertEqual(cm.credentials.count, 0)
        XCTAssertNil(cm.lastUsedCredential)
    }
}
