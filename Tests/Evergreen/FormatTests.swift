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
        XCTAssertEqual(labels.count, 25)
        XCTAssertEqual(labels[0], "All Formats")
    }
    
    func test_Format_getSearchFormatForSpinnerLabel() {
        let searchFormat = Format.getSearchFormat(forSpinnerLabel: "All Books")
        XCTAssertEqual(searchFormat, "book")
    }
    
    func test_Format_getSearchFormatFromMRAResponse() {
        // https://gapines.org/osrf-gateway-v1?service=open-ils.pcrud&method=open-ils.pcrud.retrieve.mra&param=%22ANONYMOUS%22&param=2255449
        let mraResponse = """
            "biog"=>"d", "conf"=>"0", "cont"=>" ", "ctry"=>"nyu", "fest"=>"0", "ills"=>" ", "indx"=>"0", "cont1"=>" ", "date1"=>"1994", "ills1"=>" ", "audience"=>" ", "cat_form"=>"a", "language"=>"eng", "lit_form"=>"0", "bib_level"=>"m", "item_lang"=>"eng", "item_type"=>"a", "pub_status"=>"s", "icon_format"=>"book", "search_format"=>"book", "mr_hold_format"=>"book"
            """
        let searchFormat = Format.getSearchFormat(fromMRAResponse: mraResponse)
        XCTAssertEqual(searchFormat, "book")
        
        // https://gapines.org/osrf-gateway-v1?service=open-ils.pcrud&method=open-ils.pcrud.retrieve.mra&param=%22ANONYMOUS%22&param=4132282
        let response2 = "\"conf\"=>\"0\", \"cont\"=>\" \", \"ctry\"=>\"meu\", \"fest\"=>\"0\", \"ills\"=>\" \", \"indx\"=>\"0\", \"cont1\"=>\" \", \"date1\"=>\"2000\", \"ills1\"=>\" \", \"audience\"=>\"c\", \"cat_form\"=>\"a\", \"language\"=>\"eng\", \"lit_form\"=>\"1\", \"bib_level\"=>\"m\", \"item_form\"=>\"d\", \"item_lang\"=>\"eng\", \"item_type\"=>\"a\", \"pub_status\"=>\"s\", \"icon_format\"=>\"lpbook\", \"search_format\"=>\"book\", \"mr_hold_format\"=>\"lpbook\""
        let format2 = Format.getSearchFormat(fromMRAResponse: response2)
        XCTAssertEqual(format2, "lpbook")
        
        // https://gapines.org/osrf-gateway-v1?service=open-ils.pcrud&method=open-ils.pcrud.retrieve.mra&param=%22ANONYMOUS%22&param=4221885
        let response3 = "\"ctry\"=>\"cau\", \"tech\"=>\"l\", \"date1\"=>\"2004\", \"audience\"=>\" \", \"cat_form\"=>\"a\", \"language\"=>\"eng\", \"type_mat\"=>\"v\", \"bib_level\"=>\"m\", \"enc_level\"=>\"I\", \"item_lang\"=>\"eng\", \"item_type\"=>\"g\", \"vr_format\"=>\"g\", \"pub_status\"=>\"s\""
        let format3 = Format.getSearchFormat(fromMRAResponse: response3)
        XCTAssertEqual(format3, "")

    }

    func test_Format_getDisplayLabel() {
        // case where spinnerLabel != displayLabel
        XCTAssertEqual(Format.getDisplayLabel(forSearchFormat: "book"), "Book")
        XCTAssertEqual(Format.getDisplayLabel(forSearchFormat: "dvd"), "DVD")
    }
    
    func test_Format_isOnlineResource() {
        XCTAssertTrue(Format.isOnlineResource(forSearchFormat: "ebook"))
        XCTAssertFalse(Format.isOnlineResource(forSearchFormat: "book"))
    }
}
