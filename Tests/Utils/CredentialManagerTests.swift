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
        let am = CredentialManager(valet: valet)
        XCTAssertNil(am.lastAccount)
        XCTAssertEqual(am.credentials.count, 0)
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
        
        let am = CredentialManager(valet: valet)
        XCTAssertEqual(am.lastAccount, Credential(username: "alice", password: "*"))
        XCTAssertEqual(am.credentials.count, 1)
        XCTAssertEqual(am.credentials.first?.username, "alice")
        XCTAssertEqual(am.credentials.first?.password, "*")
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
        
        let am = CredentialManager(valet: valet)
        XCTAssertEqual(am.lastAccount, Credential(username: "bob", password: "*b"))
        XCTAssertEqual(am.credentials.count, 3)
        XCTAssertEqual(am.credentials[0], Credential(username: "alice", password: "*a"))
        XCTAssertEqual(am.credentials[1], Credential(username: "bob", password: "*b"))
        XCTAssertEqual(am.credentials[2], Credential(username: "charlie", password: "*c"))
    }
        
    func test_loadLegacyAccount() {
        valet.set(string: alice.username, forKey: CredentialManager.legacyUsernameKey)
        valet.set(string: alice.password, forKey: CredentialManager.legacyPasswordKey)
        
        let am = CredentialManager(valet: valet)
        XCTAssertEqual(am.credentials.count, 1)
        XCTAssertEqual(am.credentials.first, alice)
        XCTAssertFalse(valet.containsObject(forKey: CredentialManager.legacyUsernameKey))
        XCTAssertFalse(valet.containsObject(forKey: CredentialManager.legacyPasswordKey))
        XCTAssertTrue(valet.containsObject(forKey: CredentialManager.storageKeyV1))
    }
    
    // Test that adding and removing works; construce CredentialManager multiple
    // times to test that state is properly saved to storage
    func test_addAndRemove() {
        var am: CredentialManager
            
        // add bob
        am = CredentialManager(valet: valet)
        am.add(credential: bob)
        XCTAssertEqual(am.credentials.count, 1)
        XCTAssertEqual(am.credentials.first, bob)
        XCTAssertEqual(am.lastAccount, bob)

        // test restored state then add alice
        am = CredentialManager(valet: valet)
        XCTAssertEqual(am.credentials.count, 1)
        XCTAssertEqual(am.credentials.first, bob)
        XCTAssertEqual(am.lastAccount, bob)
        am.add(credential: alice)
        XCTAssertEqual(am.lastAccount, alice)

        // test restored state then remove alice
        am = CredentialManager(valet: valet)
        XCTAssertEqual(am.credentials.count, 2)
        XCTAssertEqual(am.credentials.first, alice)
        am.removeCredential(forUsername: alice.username)
        XCTAssertEqual(am.lastAccount, bob)

        // test restored state then remove bob
        am = CredentialManager(valet: valet)
        XCTAssertEqual(am.credentials.count, 1)
        XCTAssertEqual(am.credentials.first, bob)
        am.removeCredential(forUsername: bob.username)
        XCTAssertEqual(am.credentials.count, 0)
        XCTAssertNil(am.lastAccount)
    }
}
