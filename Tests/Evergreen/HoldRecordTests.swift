//
//  HoldRecordTests.swift
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

class HoldRecordTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func test_parseHoldableFormats() {
        let holdableFormats = """
            {"0":[{"_attr":"mr_hold_format","_val":"book"},{"_attr":"mr_hold_format","_val":"lpbook"}],"1":[{"_attr":"item_lang","_val":"eng"}]}
            """
        let formats = EvergreenHoldRecord.parseHoldableFormats(holdableFormats: holdableFormats)
        XCTAssertEqual(2, formats.count)
        XCTAssertEqual(["book","lpbook"], formats)
    }
}
