//
//  APITests.swift
//  HemlockTests
//
//  Created by Ken Cox on 4/15/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

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
