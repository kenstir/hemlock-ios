//
//  OSRFObjectTests.swift
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

class OSRFObjectTests: XCTestCase {
   
    func test_getDate() {
        let obj = OSRFObject(["checkin_time": "2017-05-01T14:03:24-0400"])
        XCTAssertNil(obj.getDate("checkout_time"))
        let checkinDate = obj.getDate("checkin_time")
        let expectedDate = Date(timeIntervalSince1970: 1493661804)
        XCTAssertEqual(checkinDate, expectedDate)
    }
    
    func test_dateFormatting_ISO_to_UTC() {
        // parsing and reformatting date converts to UTC
        let apiDateStr = "2018-04-26T19:27:58-0400"
        let date = OSRFObject.apiDateFormatter.date(from: apiDateStr)
        let str = OSRFObject.apiDateFormatter.string(from: date!)
        XCTAssertEqual(str, "2018-04-26T23:27:58Z")
    }

    func test_dateFormatting_ISO_in_UTC() {
        // ISO8601 date in UTC stays just the same
        let apiDateStr = "2019-01-01T00:00:00Z"
        let date = OSRFObject.apiDateFormatter.date(from: apiDateStr)
        let str = OSRFObject.apiDateFormatter.string(from: date!)
        XCTAssertEqual(str, apiDateStr)
    }
    
    func test_dateFormatting_US_to_US_1() {
        // en_US date to API and back removes the leading 0
        let localDateStr = "Jan 01, 2019"
        let localDate = OSRFObject.outputDateFormatter.date(from: localDateStr)
        let str = OSRFObject.outputDateFormatter.string(from: localDate!)
        XCTAssertEqual(str, "Jan 1, 2019")
    }

    func test_dateFormatting_US_to_US_2() {
        // en_US date without the leading 0 stays the same
        let localDateStr = "Jan 1, 2019"
        let localDate = OSRFObject.outputDateFormatter.date(from: localDateStr)
        let str = OSRFObject.outputDateFormatter.string(from: localDate!)
        XCTAssertEqual(str, localDateStr)
    }
    
    func test_hoursFormatting_API_to_PM() {
        let apiHoursStr = "22:00:00"
        let date = OSRFObject.apiHoursFormatter.date(from: apiHoursStr)
        XCTAssertNotNil(date)
        let localHoursStr = OSRFObject.outputHoursFormatter.string(from: date!)
        // as of macOS 14.2.1, the localHoursStr contains a utf-8 narrow no-break space,
        // so this is not a good test but I'm not ready to discard it yet.
        let s = localHoursStr[localHoursStr.startIndex..<localHoursStr.index(localHoursStr.startIndex, offsetBy: 5)]
        XCTAssertEqual(s, "10:00")// PM
    }

    func test_equatable() {
        let obj1 = OSRFObject(["a": 1, "b": nil])
        let obj2 = OSRFObject(["b": nil, "a": 1])
        // sometimes fails on Xcode 10 due to dict reordering
        XCTAssertEqual(obj1, obj2)
        
        let obj3 = OSRFObject(["b": nil, "a": nil])
        XCTAssertNotEqual(obj2, obj3)
        
        let obj4 = OSRFObject(["b": nil, "a": 12])
        XCTAssertNotEqual(obj2, obj4)
        
        let obj5 = OSRFObject(["b": nil, "a": 1, "c": "any"])
        XCTAssertNotEqual(obj2, obj5)
    }
}
