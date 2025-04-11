//
//  Copyright (C) 2025 Kenneth H. Cox
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

class CopyLocationCountsTests: XCTestCase {

    override func setUp() {
        super.setUp()

        TestUtils.loadExampleOrgs()
    }

    func test_ignoreCopyFromNonVisibleOrg() {
        // orgID 7 is not visible
        let jsonPayload = """
            [[["4","","YA B JOHNSON","","NONFIC",{"0":1}],
              ["5","","YA B JOHNSON","","NONFIC",{"1":1}],
              ["7","","YA B JOHNSON","","NONFIC",{"0":1}]]]
            """
        guard let arr = JSONTestUtils.parseArray(fromJSONStr: jsonPayload) else {
            XCTFail("Failed to parse JSON array")
            return
        }
        let copyLocationCounts = CopyLocationCounts.makeArray(fromPayload: arr)
        XCTAssertEqual(2, copyLocationCounts.count)
        XCTAssertEqual(4, copyLocationCounts[0].orgID)
        XCTAssertEqual(5, copyLocationCounts[1].orgID)
    }
}
