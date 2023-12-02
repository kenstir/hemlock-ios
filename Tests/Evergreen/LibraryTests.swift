//
//  LibraryTests.swift
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
        XCTAssertEqual(sut.name, "")
        sut = Library("https://bark.cwmars.org", name: "C/W MARS")
        XCTAssertEqual(sut.name, "C/W MARS")
    }

}
