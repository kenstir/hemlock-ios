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

    override func setUp() {
        super.setUp()
        setUpOrgTypes()
        setUpOrgs()
    }

    func setUpOrgTypes() {
        let orgTypeConsortium = OSRFObject([
            "id": 1,
            "name": "Consortium",
            "opac_label": "All Libraries",
            "can_have_users": "f",
            "can_have_vols": "f",
        ])
        let orgTypeLibrary = OSRFObject([
            "id": 3,
            "name": "Library",
            "opac_label": "This Library",
            "can_have_users": "t",
            "can_have_vols": "t",
        ])
        let orgTypeSystem = OSRFObject([
            "id": 2,
            "name": "System",
            "opac_label": "All Branches of This Library",
            "can_have_users": "f",
            "can_have_vols": "f",
        ])
        OrgType.loadOrgTypes(fromArray: [orgTypeConsortium, orgTypeLibrary, orgTypeSystem])
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
        let consortiumObj = OSRFObject([
            "id": 1,
            "ou_type": 1,
            "shortname": "CONS",
            "name": "Bibliomation",
            "opac_visible": "t",
            "parent_ou": nil,
        "children": [systemObj]])
        try? Organization.loadOrganizations(fromObj: consortiumObj)
    }

    func test_loadOrgTypes() {
        XCTAssertEqual(OrgType.orgTypes.count, 3)

        let orgType = OrgType.find(byId: 1)
        XCTAssertEqual(orgType?.canHaveUsers, false)
        XCTAssertEqual(orgType?.canHaveVols, false)
        XCTAssertEqual(orgType?.label, "All Libraries")
        
        let notype = OrgType.find(byId: 999)
        XCTAssertNil(notype)
    }

    func test_findOrg() {
        let org = Organization.find(byId: 1)
        XCTAssertEqual(org?.shortname, "CONS")

        let cons = Organization.consortium()
        XCTAssertEqual(cons?.id, 1)

        let system = Organization.find(byId: 28)
        XCTAssertEqual(system?.shortname, "BETSYS")
        XCTAssertEqual(system?.orgType?.canHaveUsers, false)
        XCTAssertEqual(system?.orgType?.canHaveVols, false)

        let lib = Organization.find(byId: 29)
        XCTAssertEqual(lib?.name, "Bethel Public Library")
        XCTAssertEqual(lib?.shortname, "BETHEL")
        XCTAssertEqual(lib?.orgType?.canHaveUsers, true)
        XCTAssertEqual(lib?.orgType?.canHaveVols, true)
        
        let nolib = Organization.find(byId: 999)
        XCTAssertNil(nolib)
    }

    func test_findOrgByShortName() {
        let lib = Organization.find(byShortName: "BETHEL")
        XCTAssertEqual(29, lib?.id)
        
        let nolib = Organization.find(byShortName: "XYZZY")
        XCTAssertNil(nolib)
    }

    func test_spinnerLabels() {
        let labels = Organization.getSpinnerLabels()
        XCTAssertEqual(labels, ["Bibliomation", "   Bethel Public Library"])
        
        // check that the position of an org in the spinner labels is
        // the same as the position of that org in the orgs array
        let orgFromSpinner = Organization.find(byName: labels.last?.trim())
        XCTAssertEqual(orgFromSpinner?.name, "Bethel Public Library")
        let orgFromGlobal = Organization.visibleOrgs[labels.endIndex-1]
        XCTAssertEqual(orgFromGlobal.name, "Bethel Public Library")
        XCTAssertEqual(orgFromSpinner?.id, orgFromGlobal.id)
    }

    func test_orgAncestry() {
        let ancestors = Organization.ancestors(byShortName: "BETHEL")
        XCTAssertEqual(ancestors, ["BETHEL", "BETSYS", "CONS"])
    }

    func test_orgDimensionKey() {
        let branchOrg = Organization.find(byShortName: "BETHEL")
        let systemOrg = Organization.find(byShortName: "BETSYS")
        let consortiumOrg = Organization.find(byId: 1)

        XCTAssertEqual(Analytics.orgDimensionKey(selectedOrg: branchOrg, defaultOrg: nil, homeOrg: nil), "null")
        XCTAssertEqual(Analytics.orgDimensionKey(selectedOrg: branchOrg, defaultOrg: branchOrg, homeOrg: branchOrg), "default")
        XCTAssertEqual(Analytics.orgDimensionKey(selectedOrg: branchOrg, defaultOrg: consortiumOrg, homeOrg: branchOrg), "home")
        XCTAssertEqual(Analytics.orgDimensionKey(selectedOrg: consortiumOrg, defaultOrg: branchOrg, homeOrg: branchOrg), "CONS")
        XCTAssertEqual(Analytics.orgDimensionKey(selectedOrg: systemOrg, defaultOrg: consortiumOrg, homeOrg: branchOrg), "other")
    }
}
