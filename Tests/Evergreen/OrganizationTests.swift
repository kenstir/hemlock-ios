//
//  OrganizationTests.swift
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

class OrganizationTests: XCTestCase {
    func test_OrgType_makeArray() {
        let dict: [String: Any] = [
            "children": NSNull(),
            "can_have_users": "f",
            "can_have_vols": "f",
            "depth": 0,
            "id": 1,
            "name": "Consortium",
            "opac_label": "All PINES Libraries",
            "org_units": NSNull()]
        let obj = OSRFObject(dict)
        let array = OrgType.makeArray([obj])
        XCTAssertEqual(array.count, 1)
        let orgType = array.first
        XCTAssertEqual(orgType?.canHaveUsers, false)
        XCTAssertEqual(orgType?.canHaveVols, false)
        XCTAssertEqual(orgType?.label, "All PINES Libraries")
    }
}

