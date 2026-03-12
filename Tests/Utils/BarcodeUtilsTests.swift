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

class BarcodeUtilsTests: XCTestCase {
    let width: Int32 = 400
    let height: Int32 = 200
    let supportedFormats: [BarcodeFormat] = [.Codabar, .Code39]

    func testEncode(_ barcode: String, format: BarcodeFormat) -> ZXBitMatrix? {
        return BarcodeUtils.tryEncode(barcode, width: width, height: height, format: format)
    }

    func testEncode(_ barcode: String, formats: [BarcodeFormat]) -> ZXBitMatrix? {
        return BarcodeUtils.tryEncode(barcode, width: width, height: height, formats: formats)
    }

    func test_encodeCodabar() {
        XCTAssertNil(testEncode("D782515578", format: .Codabar))
        XCTAssertNil(testEncode("hemlock-cool", format: .Codabar))

        XCTAssertNotNil(testEncode("55555000001234", format: .Codabar))
        XCTAssertNotNil(testEncode("11661", format: .Codabar))
    }

    func test_encodeCode39() {
        XCTAssertNotNil(testEncode("D782515578", format: .Code39))
        XCTAssertNotNil(testEncode("hemlock-cool", format: .Code39))
        XCTAssertNotNil(testEncode("55555000001234", format: .Code39))
        XCTAssertNotNil(testEncode("11661", format: .Code39))
    }
    
    func test_tryEncodeFormats() {
        // emoji should not work in either format
        XCTAssertNil(testEncode("😱", formats: [.Codabar, .Code39]))

        // D782515578 should fail in Codabar, but work in Code39
        XCTAssertNil(testEncode("D782515578", formats: [.Codabar]))
        XCTAssertNotNil(testEncode("D782515578", formats: [.Codabar, .Code39]))

        // 11611 works in either
        XCTAssertNotNil(testEncode("11611", formats: [.Codabar, .Code39]))
        XCTAssertNotNil(testEncode("11611", formats: [.Code39, .Codabar]))
    }
}
