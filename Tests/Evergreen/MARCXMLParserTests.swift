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

    let marcXMLFile = "TestData/marcxml_partial_3185816" // .xml
    var marcRecord = MARCRecord()

    override func setUp() {
        super.setUp()

        loadMARCRecord()
    }

    func loadMARCRecord() {
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: marcXMLFile, ofType: "xml") else
        {
            XCTFail("unable to open xml resource")
            return
        }
        let parser = MARCXMLParser(contentsOf: URL(fileURLWithPath: path))
        guard let marcRecord = try? parser.parse() else {
            XCTFail(parser.error?.localizedDescription ?? "??")
            return
        }
        self.marcRecord = marcRecord
    }

    func test_marcXML_basic() {
        for df in marcRecord.datafields {
            print("tag \(df.tag) ind1 \(df.ind1) ind2 \(df.ind2)")
            for sf in df.subfields {
                if sf.code != "x" {
                    print("... code \(sf.code) text \(sf.text ?? "")")
                }
            }
        }

        // only a subset of 856 tags are kept, see MARCXMLParser
        let datafields = marcRecord.datafields
        XCTAssertEqual(4, datafields.count)
        let online_locations = datafields.filter { $0.ind1 == "4" }
        XCTAssertEqual(4, online_locations.count)
        
        // subfield 9 is used for located URIs;
        // NORFLK appears in 2, NEWTWN in 4
        var libShortCode = "NORFLK"
        var matching_links = datafields.filter { datafield in
            return datafield.subfields.contains(where: { $0.code == "9" && $0.text == libShortCode })
        }
        XCTAssertEqual(2, matching_links.count)
        libShortCode = "NEWTWN"
        matching_links = datafields.filter { datafield in
            return datafield.subfields.contains(where: { $0.code == "9" && $0.text == libShortCode })
        }
        XCTAssertEqual(4, matching_links.count)
    }
}
