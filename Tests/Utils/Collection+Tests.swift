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

class CollectionExtensionsTests: XCTestCase {

    func test_firstIndexOrZeroWhere() {
        let array = [1, 2, 3, 4, 5]

        let index = array.firstIndexOrZero(where: { $0 > 3 })
        XCTAssertEqual(index, 3)

        let indexNotFound = array.firstIndexOrZero(where: { $0 < 0 })
        XCTAssertEqual(indexNotFound, 0)
    }

    func test_firstIndexOrZeroOf() {
        let array = ["alice", "bob", "charlie"]

        let index = array.firstIndexOrZero(of: "bob")
        XCTAssertEqual(index, 1)

        let indexNotFound = array.firstIndexOrZero(of: "eve")
        XCTAssertEqual(indexNotFound, 0)
    }
}
