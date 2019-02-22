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
import ZXingObjC
@testable import Hemlock

class BarcodeTests: XCTestCase {
    let width: Int32 = 400
    let height: Int32 = 200

    func testEncode(_ barcode: String, format: BarcodeFormat) -> ZXBitMatrix? {
        return BarcodeUtils.tryEncode(barcode, width: width, height: height, format: format)
    }

    func test_encodeCodabar() {
        XCTAssertNotNil(testEncode("55555000001234", format: .Codabar))
        XCTAssertNotNil(testEncode("11661", format: .Codabar))

        XCTAssertNil(testEncode("D782515578", format: .Codabar))
    }

    func test_encodeCode39() {
        XCTAssertNotNil(testEncode("D782515578", format: .Code39))
        XCTAssertNotNil(testEncode("55555000001234", format: .Code39))
        XCTAssertNotNil(testEncode("11661", format: .Code39))
    }
}
