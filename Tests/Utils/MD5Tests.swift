//
//  MD5Tests.swift
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

class MD5Tests: XCTestCase {
    func test_md5() {
        XCTAssertEqual(md5("blah"), "6f1ed002ab5595859014ebf0951522d9")
        XCTAssertEqual(md5("a:b:c"), "02cc8f08398a4f3113b554e8105ebe4c")
    }

    func test_md5_new() {
        let s = "$2a$10$iHp694Dza1H5EsOKib08eu"
        XCTAssertEqual(md5(s), "15c4ff9d8b2fb5384845293ea3dd6e2b")
    }
}
