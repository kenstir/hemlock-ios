//
//  UtilsTests.swift
//
//  Copyright (C) 2020 Kenneth H. Cox
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

class UtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_coalesce() {
        XCTAssertEqual(1, Utils.coalesce(nil, 1, 2))
        XCTAssertEqual(1, Utils.coalesce(1, 2))
        let vnil: Int? = nil
        XCTAssertNil(Utils.coalesce(vnil, nil))
    }
    
    func test_coalesceString() {
        XCTAssertEqual("508-555-1212", Utils.coalesce(nil, "", "508-555-1212"))
        XCTAssertNil(Utils.coalesce("", nil))
        let vnil: String? = nil
        XCTAssertNil(Utils.coalesce(vnil, nil))
    }
}
