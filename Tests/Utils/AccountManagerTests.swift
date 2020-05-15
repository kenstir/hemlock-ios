//
//  AccountManagerTests.swift
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

class AccountManagerTests: XCTestCase {
    
    let valet = Valet.valet(with: Identifier(nonEmpty: "HemlockTests")!, accessibility: .whenUnlockedThisDeviceOnly)
    let alice = StoredAccount(username: "alice", password: "aliceisgreat")
    let bob = StoredAccount(username: "bob", password: "bobiscool")

    override func setUp() {
        // cleanup any leftovers from prior runs
        valet.removeAllObjects()
    }

    func test_load_empty() {
        let am = AccountManager(valet: valet)
        XCTAssertNil(am.lastAccount)
        XCTAssertEqual(am.accounts.count, 0)
    }
    
    func test_load_oneAccount() {
        let str = """
            {
              "lastUsername": "alice",
              "accounts": [
                {"username": "alice", "password": "*"}
              ]
            }
            """
        
        guard let data = str.data(using: .utf8) else {
            XCTFail()
            return
        }
        valet.set(object: data, forKey: AccountManager.storageKey)
        
        let am = AccountManager(valet: valet)
        XCTAssertEqual(am.lastAccount, StoredAccount(username: "alice", password: "*"))
        XCTAssertEqual(am.accounts.count, 1)
        XCTAssertEqual(am.accounts.first?.username, "alice")
        XCTAssertEqual(am.accounts.first?.password, "*")
    }
    
    func test_load_multipleAccounts() {
        let str = """
            {
              "lastUsername": "bob",
              "accounts": [
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
        valet.set(object: data, forKey: AccountManager.storageKey)
        
        let am = AccountManager(valet: valet)
        XCTAssertEqual(am.lastAccount, StoredAccount(username: "bob", password: "*b"))
        XCTAssertEqual(am.accounts.count, 3)
        XCTAssertEqual(am.accounts[0], StoredAccount(username: "alice", password: "*a"))
        XCTAssertEqual(am.accounts[1], StoredAccount(username: "bob", password: "*b"))
        XCTAssertEqual(am.accounts[2], StoredAccount(username: "charlie", password: "*c"))
    }
    
    func test_storeAccount() {
        let am = AccountManager(valet: valet)
        am.add(account: bob)
        XCTAssertEqual(am.accounts.count, 1)
        XCTAssertEqual(am.accounts.first, bob)

        let am2 = AccountManager(valet: valet)
        XCTAssertEqual(am2.accounts.count, 1)
        XCTAssertEqual(am2.accounts.first, bob)
        am2.add(account: alice)
        
        let am3 = AccountManager(valet: valet)
        XCTAssertEqual(am3.accounts.count, 2)
        XCTAssertEqual(am3.accounts.first, alice)
    }
}
