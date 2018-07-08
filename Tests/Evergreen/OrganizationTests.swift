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
    	let dict: JSONDictionary = [
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
    
    func test_Organization_load() {
        var cons = OSRFObject([
            "name": "Example Consortium",
            "ou_type": 1,
            "opac_visible": "t",
            "parent_ou": nil,
            "id": 1,
            "shortname": "CONS"])
        var sys1 = OSRFObject([
            "name": "Example System 1",
            "ou_type": 2,
            "opac_visible": "t",
            "parent_ou": 1,
            "id": 2,
            "shortname": "SYS1"])
        let br1 = OSRFObject([
            "name": "Example Branch 1",
            "ou_type": 3,
            "opac_visible": "t",
            "parent_ou": 2,
            "id": 4,
            "shortname": "BR1"])
        let br2 = OSRFObject([
            "name": "Example Branch 2",
            "ou_type": 3,
            "opac_visible": "t",
            "parent_ou": 2,
            "id": 5,
            "shortname": "BR2"])
        sys1.dict["children"] = [br1,br2]
        cons.dict["children"] = [sys1]

        do {
            try Organization.loadOrganizations(fromObj: cons)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        let org = Organization.find(byId: 1)
        XCTAssertEqual(org?.name, "Example Consortium")
        XCTAssertEqual(org?.shortname, "CONS")

        let system1 = Organization.find(byId: 2)
        XCTAssertEqual(system1?.name, "Example System 1")
        XCTAssertEqual(system1?.shortname, "SYS1")

        let branch2 = Organization.find(byId: 5)
        XCTAssertEqual(branch2?.name, "Example Branch 2")
        XCTAssertEqual(branch2?.shortname, "BR2")
    }
}

