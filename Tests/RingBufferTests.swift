//
//  RingBufferTests.swift
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
import Alamofire
import Foundation
@testable import Hemlock

class RingBufferTests: XCTestCase {
    
    func testBasics() {
        // initial rb is empty
        var rb = RingBuffer<Int>(count: 4)
        XCTAssertTrue(rb.elementsEqual([]))

        // after adding 2 we check
        rb.write(1)
        rb.write(2)
        XCTAssertTrue(rb.elementsEqual([1,2]))
        
        // we remove 2 good values then read() returns nil
        var e = rb.read()
        XCTAssertEqual(1, e)
        e = rb.read()
        XCTAssertEqual(2, e)
        e = rb.read()
        XCTAssertEqual(nil, e)
        e = rb.read()
        XCTAssertEqual(nil, e)
    }

    func testWraparound() {
        var rb = RingBuffer<String>(count: 3)
        XCTAssertNotNil(rb)

        // we can add 3 items
        rb.write("a")
        rb.write("b")
        rb.write("c")
        XCTAssertTrue(rb.elementsEqual(["a","b","c"]))

        // then we wraparound
        rb.write("d")
        XCTAssertTrue(rb.elementsEqual(["b","c","d"]))
    }

}
