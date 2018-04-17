//
//  APITests.swift
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

class APITests: XCTestCase {
    var sut: API?
    
    override func setUp() {
        super.setUp()
        API.library = Library("https://example.org")
    }
    
    override func tearDown() {
        // Put teardown code here.
        super.tearDown()
    }
    
    func test_gatewayParam_podTypes() {
        let p1 = API.gatewayParam("hemlock")
        XCTAssertEqual(p1, "\"hemlock\"")
        let p2 = API.gatewayParam(42)
        XCTAssertEqual(p2, "42")
        let p3 = API.gatewayParam(3.14)
        XCTAssertEqual(p3, "3.14")
    }
    
    func test_gatewayParam_unknownType() {
        let p1 = API.gatewayParam(Set<Int>())
        XCTAssertEqual(p1, "")
    }
    
    func test_gatewayUrl_basic() {
        let u1 = API.gatewayURL(service: API.auth, method: API.authInit, args: ["hemlock"])
        XCTAssertEqual(u1, "https://example.org/osrf-gateway-v1?service=open-ils.auth&method=open-ils.auth.authenticate.init&param=\"hemlock\"")
    }
}
