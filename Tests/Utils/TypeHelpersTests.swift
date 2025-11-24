//
//  Copyright (c) 2025 Kenneth H. Cox
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
import Foundation
@testable import Hemlock

class TypeHelpersTests: XCTestCase {
    func makeBibRecord(id: Int) -> BibRecord {
        return MBRecord(id: id)
    }

    func evergreenImpl(_ bibRecord: Any) throws {
        let record: MBRecord = try requireType(bibRecord)
        print("evergreenImpl: record id = \(record.id)")
    }

    func test_requireType_success() throws {
        let bibRecord = makeBibRecord(id: 1)
        let record: MBRecord = try requireType(bibRecord)
        XCTAssertEqual(record.id, 1)
    }

    func test_requireType_throws() {
        let str = "whatever"
        XCTAssertThrowsError(try evergreenImpl(str)) { error in
            let errorMessage = error.localizedDescription
            XCTAssertEqual(errorMessage, "Internal Error: Type mismatch: expected MBRecord, got String")
        }
    }
}
