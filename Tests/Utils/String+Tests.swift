//
//  Copyright (c) 2026 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import Hemlock

class StringExtensionTests: XCTestCase {
    struct Case {
        let template: String
        let values: [String: String]
        let expected: String
    }

    func test_expandTemplate() {
        let cases = [
            Case(template: "{baseURL}/record/{recordID}#awards",
                 values: ["baseURL": "https://example.com", "recordID": "1"],
                 expected: "https://example.com/record/1#awards"),
            Case(template: "{id}?{id}#{id}", values: ["id": "1"], expected: "1?1#1"),
            Case(template: "beginning_{s}_end", values: ["s": "middle"], expected: "beginning_middle_end"),
            Case(template: "No tokens here", values: ["id": "1"], expected: "No tokens here"),
        ]
        for testCase in cases {
            let got = try? testCase.template.expandTemplate(values: testCase.values)
            XCTAssertEqual(got ?? "nil", testCase.expected,
                           "template \"\(testCase.template)\" with values \(testCase.values)")
        }
    }

    func test_expandTemplate_missingKey() {
        let template = "Missing {key}"
        XCTAssertThrowsError(try template.expandTemplate(values: [:])) { error in
            print("Error: \(error.localizedDescription)")
        }
    }
}
