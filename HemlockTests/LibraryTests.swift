//
//  LibraryTests.swift
//  HemlockTests
//
//  Created by Ken Cox on 4/15/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import XCTest
@testable import Hemlock

class LibraryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        let sut: Library = Library(name: "Georgia PINES", directoryName: "Georgia, US (Georgia PINES)", url: "https://gapines.org")
        XCTAssertEqual(sut.name, "Georgia PINES")
        XCTAssertEqual(sut.url, "https://gapines.org")
    }
    
}
