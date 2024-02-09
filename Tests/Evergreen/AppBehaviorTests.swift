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

    var testBundle = Bundle()

    override func setUp() {
        super.setUp()

        testBundle = Bundle(for: type(of: self))

        TestUtils.loadExampleOrgs()
    }

    func printLinks(_ links: [Link]) {
        print("\(links.count) links:")
        for link in links {
            print("  [\(link.text)] (\(link.href))")
        }
    }

    func test_getLinksFromRecordWithConsortiumInSubfield9s() {
        let appBehavior = TestAppBehavior()
        let marcRecord = TestUtils.loadMARCRecord(fromBundle: testBundle, fileBaseName: "TestData/marcxml_ebook_1_cons")
        let datafields = marcRecord.datafields

        // subfield 9 has CONS which is an ancestor of everything
        let linksForBR1 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "BR1")
        printLinks(linksForBR1)
        XCTAssertEqual(1, linksForBR1.count)
        XCTAssertEqual("Click to access online", linksForBR1.first?.text)
        XCTAssertEqual("http://example.com/ebookapi/t/001", linksForBR1.first?.href)
        let linksForSYS1 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "SYS1")
        printLinks(linksForSYS1)
        XCTAssertEqual(1, linksForSYS1.count)
        XCTAssertEqual("Click to access online", linksForSYS1.first?.text)
        XCTAssertEqual("http://example.com/ebookapi/t/001", linksForSYS1.first?.href)
    }

    func test_getLinksFromRecordWithTwo856Tags() {
        let appBehavior = TestAppBehavior()
        let marcRecord = TestUtils.loadMARCRecord(fromBundle: testBundle, fileBaseName: "TestData/marcxml_ebook_2_two_856_tags")
        let datafields = marcRecord.datafields

        // this record has 2 856 tags, one with BR1 and one with BR2
        let linksForBR1 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "BR1")
        printLinks(linksForBR1)
        XCTAssertEqual(1, linksForBR1.count)
        XCTAssertEqual("Access for Branch 1 patrons only", linksForBR1.first?.text)
        XCTAssertEqual("http://example.com/ebookapi/t/002", linksForBR1.first?.href)
        let linksForBR2 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "BR2")
        printLinks(linksForBR2)
        XCTAssertEqual(1, linksForBR2.count)
        XCTAssertEqual("Access for Branch 2 patrons only", linksForBR2.first?.text)
        XCTAssertEqual("http://example.com/ebookapi/t/002", linksForBR2.first?.href)
        let linksForSYS1 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "SYS1")
        printLinks(linksForSYS1)
        XCTAssertEqual(0, linksForSYS1.count)
    }

    func test_getLinksFromRecordWithTwoSubfield9s() {
        let appBehavior = TestAppBehavior()
        let marcRecord = TestUtils.loadMARCRecord(fromBundle: testBundle, fileBaseName: "TestData/marcxml_ebook_2_two_subfield_9s")
        let datafields = marcRecord.datafields

        // this record has 2 subfield 9s, with BR1 and BR2
        let linksForBR1 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "BR1")
        printLinks(linksForBR1)
        XCTAssertEqual(1, linksForBR1.count)
        XCTAssertEqual("Access for Branch 1 or Branch 2 patrons", linksForBR1.first?.text)
        XCTAssertEqual("http://example.com/ebookapi/t/002", linksForBR1.first?.href)
        let linksForBR2 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "BR2")
        printLinks(linksForBR2)
        XCTAssertEqual(1, linksForBR2.count)
        XCTAssertEqual("Access for Branch 1 or Branch 2 patrons", linksForBR2.first?.text)
        XCTAssertEqual("http://example.com/ebookapi/t/002", linksForBR2.first?.href)
        let linksForSYS1 = appBehavior.getLinks(fromMarcRecord: marcRecord, forSearchOrg: "SYS1")
        printLinks(linksForSYS1)
        XCTAssertEqual(0, linksForSYS1.count)
    }
}
