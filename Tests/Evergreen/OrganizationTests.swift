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
    	let orgTypeConsortium = OSRFObject([
            "id": 1,
            "name": "Consortium",
            "opac_label": "All Libraries"
            "can_have_users": "f",
            "can_have_vols": "f",
	])
    	let orgTypeLibrary = OSRFObject([
            "id": 3,
            "name": "Library",
            "opac_label": "This Library"
            "can_have_users": "t",
            "can_have_vols": "t",
	])
    	let orgTypeSystem = OSRFObject([
            "id": 2,
            "name": "System",
            "opac_label": "All Branches of This Library"
            "can_have_users": "f",
            "can_have_vols": "f",
	])
        let array = OrgType.makeArray([orgTypeConsortium, orgTypeLibrary, orgTypeSystem])
        XCTAssertEqual(array.count, 3)
        let orgType = array.first
        XCTAssertEqual(orgType?.canHaveUsers, false)
        XCTAssertEqual(orgType?.canHaveVols, false)
        XCTAssertEqual(orgType?.label, "All Libraries")
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

    func setUpOrgs() {
        let branchObj = OSRFObject([
            "id": 29,
            "ou_type": 3,
            "shortname": "BETHEL",
	    "name": "Bethel Public Library",
            "opac_visible": "t",
            "parent_ou": 28,
	    "children": nil])
        let systemObj = OSRFObject([
            "id": 28,
            "ou_type": 2,
            "shortname": "BETSYS",
            "name": "Bethel",
            "opac_visible": "f",
            "parent_ou": 1,
	    "children": [branchObj]])
        var consortiumObj = OSRFObject([
            "id": 1,
            "ou_type": 1,
            "shortname": "CONS",
            "name": "Bibliomation",
            "opac_visible": "t",
            "parent_ou": nil,
	    "children": [systemObj]])
	Organization.loadOrganizations(fromObj: consortiumObj)
    }

    func setUp() {
        setUpOrgs()
    }

    func test_loadOrgTypes() {
        setUpOrgTypes()
        assertEquals(3, EgOrg.orgTypes.size)

        val topOrgType = EgOrg.findOrgType(1)
        assertEquals(topOrgType?.name, "Consortium")

        assertNull(EgOrg.findOrgType(999))
    }

    func test_loadOrganizations() {
        setUp()

        assertTrue(EgOrg.allOrgs.isNotEmpty())
    }

    func test_findOrg() {
        setUp()

        val lib = EgOrg.findOrg(29)
        assertEquals("BETHEL", lib?.shortname)

        assertNull(EgOrg.findOrg(999))
    }

    func test_findOrgByShortName() {
        setUp()

        val lib = EgOrg.findOrgByShortName("BETHEL")
        assertEquals(29, lib?.id)
    }

    func test_spinnerLabels() {
        setUp()

        val lib = EgOrg.findOrgByShortName("BETHEL")
        assertEquals("   ", lib?.indentedDisplayPrefix)

        val labels = EgOrg.orgSpinnerLabels()
        assertEquals(arrayListOf("Bibliomation", "   Bethel Public Library"), labels)
    }

    func test_invisibleOrgsAreLoaded() {
        setUp()

        assertEquals(3, EgOrg.allOrgs.size)
        assertEquals(2, EgOrg.visibleOrgs.size)

        val lib = EgOrg.findOrg(29)
        assertEquals(true, lib?.opac_visible)
        assertEquals("BETHEL", lib?.shortname)
        assertTrue(lib!!.orgType!!.canHaveUsers)
        assertTrue(lib!!.orgType!!.canHaveVols)

        val system = EgOrg.findOrg(28)
        assertEquals(false, system?.opac_visible)
        assertEquals("BETSYS", system?.shortname)
        assertFalse(system!!.orgType!!.canHaveUsers)
        assertFalse(system!!.orgType!!.canHaveVols)

        val cons = EgOrg.findOrg(1)
        assertEquals(true, cons?.opac_visible)
        assertEquals("CONS", cons?.shortname)
        assertFalse(system!!.orgType!!.canHaveUsers)
        assertFalse(system!!.orgType!!.canHaveVols)
    }

    func test_orgAncestry() {
        setUp()

        val libAncestry = EgOrg.getOrgAncestry("BETHEL")
        assertEquals(arrayListOf("BETHEL", "BETSYS", "CONS"), libAncestry)
    }
}
