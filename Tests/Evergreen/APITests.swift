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
    
    func test_gatewayParam_podTypes() {
        let p1 = API.gatewayParams(["hemlock"])
        XCTAssertEqual(p1, ["\"hemlock\""])
        let p2 = API.gatewayParams([42])
        XCTAssertEqual(p2, ["42"])
        let p3 = API.gatewayParams([3.14])
        XCTAssertEqual(p3, ["3.14"])
    }
    
    func test_gatewayParam_jsonObject() {
        let authtoken = "deadbeef"
        let complexParam = ["active": 1]
        let p1 = API.gatewayParams([authtoken, complexParam])
        XCTAssertEqual(p1, ["\"deadbeef\"","{\"active\":1}"])
    }
    
    func test_createRequest_basic() {
        let request = API.createRequest(service: API.auth, method: API.authInit, args: ["hemlock"])
        print("request:  \(request.description)")
        XCTAssertEqual(request.request?.url?.path, "/osrf-gateway-v1")
    }
}
