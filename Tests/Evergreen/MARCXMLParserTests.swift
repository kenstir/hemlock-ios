//
//  MARCXMLParserTests.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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
import Foundation
@testable import Hemlock

class MARCXMLParserTests: XCTestCase {

    var testBundle: Bundle?
    let marcXMLFile = "TestData/marcxml_partial_3185816" // .xml
    
    override func setUp() {
        super.setUp()
        
        testBundle = Bundle(for: type(of: self))
    }
    
    func test_marcXML_basic() {
        
        guard let path = testBundle?.path(forResource: marcXMLFile, ofType: "xml") else
        {
            XCTFail("unable to open xml resource")
            return
        }
        let parser = MARCXMLParser(contentsOf: URL(fileURLWithPath: path))
        if let marcRecord = try? parser.parse() {
            XCTAssertNotNil(marcRecord)
            let datafields = marcRecord.datafields
            XCTAssertEqual(6, datafields.count)
        } else {
            XCTFail(parser.error?.localizedDescription ?? "??")
        }
    }
    
    func test_foo() {
        XCTAssertTrue(true)
    }
}
