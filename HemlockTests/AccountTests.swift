//
//  AccountTests.swift
//  hemlock.iosTests
//
//  Created by Ken Cox on 4/8/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import XCTest
@testable import Hemlock

class AccountTests: XCTestCase {
    var sut: Account!
    
    override func setUp() {
        super.setUp()
        sut = Account(name: "hemlock")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_Account_init() {
        XCTAssertEqual(sut.name, "hemlock")
    }
    
}
