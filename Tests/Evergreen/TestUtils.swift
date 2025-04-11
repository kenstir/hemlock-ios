//
//  Copyright (C) 2024 Kenneth H. Cox
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
import Foundation
@testable import Hemlock

class TestAppBehavior: BaseAppBehavior {
    override func isVisibleToOrg(_ datafield: MARCDatafield, orgShortName: String?) -> Bool {
        return isVisibleViaLocatedURI(datafield, orgShortName: orgShortName);
    }

    override func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        return getOnlineLocationsFromMARC(record: record, forSearchOrg: orgShortName)
    }
}

class TestUtils {

    static func loadExampleOrgs() {
        let br1 = OSRFObject([
            "id": 4,
            "ou_type": 3,
            "shortname": "BR1",
            "name": "Example Branch 1",
            "opac_visible": "t",
            "parent_ou": 2,
            "children": nil])
        let br2 = OSRFObject([
            "id": 5,
            "ou_type": 3,
            "shortname": "BR2",
            "name": "Example Branch 2",
            "opac_visible": "t",
            "parent_ou": 2,
            "children": nil])
        let sys1 = OSRFObject([
            "id": 2,
            "ou_type": 2,
            "shortname": "SYS1",
            "name": "Example System 1",
            "opac_visible": "t",
            "parent_ou": 1,
            "children": [br1, br2]])
        let br3 = OSRFObject([
            "id": 6,
            "ou_type": 3,
            "shortname": "BR3",
            "name": "Example Branch 3",
            "opac_visible": "t",
            "parent_ou": 3,
            "children": nil])
        let br4 = OSRFObject([
            "id": 7,
            "ou_type": 3,
            "shortname": "BR4",
            "name": "Example Branch 4",
            "opac_visible": "f",
            "parent_ou": 3,
            "children": nil])
        let sys2 = OSRFObject([
            "id": 3,
            "ou_type": 2,
            "shortname": "SYS2",
            "name": "Example System 2",
            "opac_visible": "t",
            "parent_ou": 1,
            "children": [br3, br4]])
        let cons = OSRFObject([
            "id": 1,
            "ou_type": 1,
            "shortname": "CONS",
            "name": "Example Consortium",
            "opac_visible": "t",
            "parent_ou": nil,
            "children": [sys1, sys2]])
        try? Organization.loadOrganizations(fromObj: cons)
    }

    static func loadMARCRecord(fromBundle bundle: Bundle, fileBaseName: String) -> MARCRecord {
        let dummyRecord = MARCRecord()
        guard let path = bundle.path(forResource: fileBaseName, ofType: "xml") else
        {
            XCTFail("unable to open xml resource")
            return dummyRecord
        }
        let parser = MARCXMLParser(contentsOf: URL(fileURLWithPath: path))
        guard let marcRecord = try? parser.parse() else {
            XCTFail(parser.error?.localizedDescription ?? "??")
            return dummyRecord
        }
        return marcRecord
    }
}
