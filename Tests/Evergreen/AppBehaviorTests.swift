//
//  Copyright (C) 2024 Kenneth H. Cox
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

class AppBehaviorTests: XCTestCase {

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

    /*
    func test_getLinks() {
        let appBehavior = BaseAppBehavior()
        let datafields = marcRecord.datafields

        // subfield 9 is used for located URIs;
        // NORFLK appears in 2, NEWTWN in 4
        // But to really test appBehavior.getLinks, we need an org tree
        var libShortCode = "NORFLK"
        var links = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: libShortCode)
        XCTAssertEqual(2, links.count)
        libShortCode = "NEWTWN"
        links = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: libShortCode)
        XCTAssertEqual(4, links.count)
    }
     */
}
