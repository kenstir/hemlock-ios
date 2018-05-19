//
//  IDLParserTests.swift
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
import Foundation
@testable import Hemlock

class IDLParserTests: XCTestCase {

    var testBundle: Bundle?
    let aoutClassIDLFile = "TestData/fm_IDL_aout" // .xml
    let subsetIDLFile = "TestData/fm_IDL_subset" // .xml
    let completeIDLFile = "TestData/fm_IDL" // .xml

    override func setUp() {
        super.setUp()
        
        testBundle = Bundle(for: type(of: self))
    }
    
    func test_IDL_singleClass() {
        
        guard let path = testBundle?.path(forResource: aoutClassIDLFile, ofType: "xml") else
        {
            XCTFail("unable to open xml resource")
            return
        }
        let parser = IDLParser(contentsOf: URL(fileURLWithPath: path))
        XCTAssertTrue(parser.parse())
        
        let fields = OSRFCoder.findClass("aout")?.fields
        XCTAssertEqual(fields?.count, 9)
    }

    func test_perf_IDL_singleClass() {
        self.measure {
            guard let path = testBundle?.path(forResource: aoutClassIDLFile, ofType: "xml") else
            {
                XCTFail("unable to open xml resource")
                return
            }
            let parser = IDLParser(contentsOf: URL(fileURLWithPath: path))
            let ok = parser.parse()
            XCTAssertTrue(ok)
        }
    }

    func test_perf_IDL_subset() {
        self.measure {
            guard let path = testBundle?.path(forResource: subsetIDLFile, ofType: "xml") else
            {
                XCTFail("unable to open xml resource")
                return
            }
            let parser = IDLParser(contentsOf: URL(fileURLWithPath: path))
            let ok = parser.parse()
            XCTAssertTrue(ok)
        }
    }

    func test_perf_fullIDL() {
        self.measure {
            guard let path = testBundle?.path(forResource: completeIDLFile, ofType: "xml") else
            {
                XCTFail("unable to open xml resource")
                return
            }
            let parser = IDLParser(contentsOf: URL(fileURLWithPath: path))
            let ok = parser.parse()
            XCTAssertTrue(ok)
        }
    }

}
