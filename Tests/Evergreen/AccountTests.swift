//
//  AccountTests.swift
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

import XCTest
@testable import Hemlock

class AccountTests: XCTestCase {
    var sut: Account!
    
    override func setUp() {
        super.setUp()
        sut = Account("hemlock", password: "***")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_Account_init() {
        XCTAssertEqual(sut.username, "hemlock")
        XCTAssertEqual(sut.password, "***")
    }
    
    func test_authtoken() {
        XCTAssertNil(sut.authtoken)
        sut.setAuthToken("f1d0f00d")
        XCTAssertNotNil(sut.authtoken)
        XCTAssertEqual(sut.authtoken, "f1d0f00d")
    }
}
