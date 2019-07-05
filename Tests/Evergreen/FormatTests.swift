//
//  FormatTests.swift
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

class FormatTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_Format_getSpinnerLabels() {
        let labels = Format.getSpinnerLabels()
        XCTAssertEqual(labels.count, 14)
        XCTAssertEqual(labels[0], "All Formats")
    }
    
    func test_Format_getSearchFormatForSpinnerLabel() {
        let searchFormat = Format.getSearchFormat(forSpinnerLabel: "All Books")
        XCTAssertEqual(searchFormat, "book")
    }

    func test_Format_getDisplayLabel() {
        // case where spinnerLabel != displayLabel
        XCTAssertEqual(Format.getDisplayLabel(forSearchFormat: "book"), "Book")
        XCTAssertEqual(Format.getDisplayLabel(forSearchFormat: "dvd"), "DVD")
        XCTAssertEqual(Format.getDisplayLabel(forSearchFormat: ""), "")
    }
    
//    func test_Format_isOnlineResource() {
//        XCTAssertTrue(Format.isOnlineResource(forSearchFormat: "ebook"))
//        XCTAssertTrue(Format.isOnlineResource(forSearchFormat: "picture"))
//        XCTAssertFalse(Format.isOnlineResource(forSearchFormat: "book"))
//    }
}
