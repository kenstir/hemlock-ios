/*
 * BookBagTests.swift
 *
 * Copyright (C) 2021 Kenneth H. Cox
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

class BookBagTests: XCTestCase {
    
    let cbrebObj = OSRFObject([
        "id": 24919,
        "name": "books to read",
        "description": nil,
        "pub": "t",
        "items": nil,
    ])
    let fleshedCbrebObj = OSRFObject([
        "id": 24919,
        "name": "books to read",
        "description": nil,
        "pub": "t",
        "items": [
            OSRFObject([
                "bucket": 24919,
                "id": 51454078,
                "target_biblio_record_entry": 2914107,
            ])
        ],
    ])
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func test_makeArray() {
        let bookBags = BookBag.makeArray([cbrebObj])
        XCTAssertEqual(1, bookBags.count)
        XCTAssertEqual(24919, bookBags.first?.id)
        XCTAssertEqual("books to read", bookBags.first?.name)
    }
    
    func test_fleshFromObject() {
        let bookBag = BookBag.makeArray([cbrebObj]).first!
        XCTAssertEqual(0, bookBag.items.count)
        
        bookBag.loadItems(fromFleshedObj: fleshedCbrebObj)
        XCTAssertEqual(51454078, bookBag.items.first?.id)
        XCTAssertEqual(2914107, bookBag.items.first?.targetId)
    }
    
    func test_filterToVisibleRecords() {
        let bookBag = BookBag.makeArray([cbrebObj]).first!
        
        let recordId = 2914107
        let queryPayload = OSRFObject([
            "count": 1,
            "ids": [[recordId, "2", "4.0"] as [Any]],
        ])
        let emptyQueryPayload = OSRFObject([
            "count": 1,
            "ids": [] as [Any],
        ])

        // case 1: recordId is visible
        bookBag.initVisibleIds(fromQueryObj: queryPayload)
        bookBag.loadItems(fromFleshedObj: fleshedCbrebObj)
        XCTAssertEqual(1, bookBag.items.count)

        // case 2: recordId is not visible
        bookBag.initVisibleIds(fromQueryObj: emptyQueryPayload)
        bookBag.loadItems(fromFleshedObj: fleshedCbrebObj)
        XCTAssertEqual(0, bookBag.items.count)
    }

    //        let mvrObj = OSRFObject([
    //            "doc_id": 1234,
    //            "title": "The Testaments",
    //            "author": "Margaret Atwood"
    //        ])
    //        let metabibRecord = MBRecord(id: 1234, mvrObj: mvrObj)
}
