//
//  FormatTests.swift
//
//  AccountTests.swift
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
        let labels = SearchFormat.getSpinnerLabels()
        XCTAssertEqual(labels.count, 25)
        XCTAssertEqual(labels[0], "All Formats")
    }
    
    func test_Format_getSearchFormat() {
        let searchFormat = SearchFormat.getSearchFormat(forSpinnerLabel: "All Books")
        XCTAssertEqual(searchFormat, "book")
    }
    
    func test_Format_getDisplayLabel() {
        // case where spinnerLabel != displayLabel
        XCTAssertEqual(SearchFormat.getDisplayLabel(forSearchFormat: "book"), "Book")
        XCTAssertEqual(SearchFormat.getDisplayLabel(forSearchFormat: "dvd"), "DVD")
    }
    
    func test_Format_isOnlineResource() {
        XCTAssertTrue(SearchFormat.isOnlineResource(forSearchFormat: "ebook"))
        XCTAssertFalse(SearchFormat.isOnlineResource(forSearchFormat: "book"))
    }
}
