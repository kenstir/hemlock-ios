//
//  MD5Tests.swift
//  HemlockTests
//
//  Created by Ken Cox on 4/16/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import XCTest
@testable import Hemlock

class MD5Tests: XCTestCase {
    func test_md5() {
        XCTAssertEqual(md5("blah"), "6f1ed002ab5595859014ebf0951522d9")
        XCTAssertEqual(md5("a:b:c"), "02cc8f08398a4f3113b554e8105ebe4c")
    }
}
