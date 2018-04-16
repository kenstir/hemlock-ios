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
    
    func test_basic() {
        let sut: Library = Library("https://gapines.org", name: "Georgia PINES", directoryName: "Georgia, US (Georgia PINES)")
        XCTAssertEqual(sut.name, "Georgia PINES")
        XCTAssertEqual(sut.url, "https://gapines.org")
    }
    
    func test_optionalArgs() {
        var sut = Library("https://gapines.org")
        XCTAssertEqual(sut.url, "https://gapines.org")
        sut = Library("https://catalog.cwmars.org", name: "C/W MARS")
        XCTAssertEqual(sut.name, "C/W MARS")
    }

}
