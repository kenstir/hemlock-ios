/*
 * Copyright (C) 2020 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import XCTest
@testable import Hemlock

class CircRecordTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func test_noRecordInfo() {
        let id = 93108558
        let circObj = OSRFObject([
            "renewal_remaining": 0,
            "auto_renewal": "f",
            "auto_renewal_remaining": 0,
            "id": id,
            "circ_type": nil,
            "copy_location": 2356,
            "target_copy": 19314463,
            "due_date": "2020-02-05T23:59:59-0500",
        ])
        let circRecord = CircRecord(id: 93108558)
        circRecord.setCircObj(circObj)

        XCTAssertEqual("Unknown Title", circRecord.title)
        XCTAssertEqual("", circRecord.author)
        XCTAssertEqual(0, circRecord.renewalsRemaining)
    }
    
    func test_basic() {
        let circObj = OSRFObject([
            "renewal_remaining": 0,
            "auto_renewal": "f",
            "auto_renewal_remaining": 0,
            "id": 93108558,
            "circ_type": nil,
            "copy_location": 2356,
            "target_copy": 19314463,
            "due_date": "2020-02-05T23:59:59-0500"
        ])
        let mvrObj = OSRFObject([
            "doc_id": 1234,
            "title": "The Testaments",
            "author": "Margaret Atwood"
        ])
        let circRecord = CircRecord(id: 93108558)
        circRecord.setCircObj(circObj)
        circRecord.setMetabibRecord(BibRecord(id: 1234, mvrObj: mvrObj))

        XCTAssertEqual("The Testaments", circRecord.title)
        XCTAssertEqual("Margaret Atwood", circRecord.author)
    }
    
    // Something borrowed from another consortium will have a target_copy but
    // a record.doc_id==-1, and the acp will have dummy_title and dummy_author
    func test_illCheckout() {
        let circObj = OSRFObject([
            "renewal_remaining": 0,
            "id": 1,
            "target_copy": 1507492,
            "due_date": "2020-02-05T23:59:59-0500"
        ])
        let mvrObj = OSRFObject([
            "doc_id": -1,
            "title": nil,
            "author": nil,
        ])
        let acpObj = OSRFObject([
            "id": 1507492,
            "dummy_author": "NO AUTHOR",
            "barcode": "SEOTESTBARCODE",
            "call_number": -1,
            "copy_number": nil,
            "dummy_isbn": "NO ISBN",
            "dummy_title": "SEO TEST",
            "status": 1
        ])
        let circRecord = CircRecord(id: 1)
        circRecord.setCircObj(circObj)
        circRecord.setMetabibRecord(BibRecord(id: -1, mvrObj: mvrObj))
        circRecord.setAcpObj(acpObj)
        
        XCTAssertEqual("SEO TEST", circRecord.title)
        XCTAssertEqual("NO AUTHOR", circRecord.author)
        XCTAssertEqual(1507492, circRecord.targetCopy)
    }
}
