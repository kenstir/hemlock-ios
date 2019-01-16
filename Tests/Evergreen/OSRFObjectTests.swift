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
