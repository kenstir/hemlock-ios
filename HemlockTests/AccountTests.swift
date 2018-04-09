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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_Account_init() {
        let sut = Account(name: "hemlock")
        XCTAssertEqual(sut.name, "hemlock")
    }
    
}
