//
//  BarcodeTests.swift
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

class BarcodeTests: XCTestCase {
    func test_isValid_Codabar14() {
        // positive tests
        XCTAssertTrue(Barcode.isValid("12345678901234", format: .Codabar))
        XCTAssertTrue(Barcode.isValid("1234", format: .Codabar))
        XCTAssertTrue(Barcode.isValid("1234-$:/+.", format: .Codabar))
        XCTAssertTrue(Barcode.isValid("123456789012345", format: .Codabar))

        // negative tests
        XCTAssertFalse(Barcode.isValid("TESTAPP", format: .Codabar))
        XCTAssertFalse(Barcode.isValid("1234E", format: .Codabar))
        XCTAssertFalse(Barcode.isValid("1234-$:/+.ABCD", format: .Codabar))
        XCTAssertFalse(Barcode.isValid("1234a", format: .Codabar))
    }
}
