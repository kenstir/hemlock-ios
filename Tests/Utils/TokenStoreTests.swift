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

class TokenStoreTests: XCTestCase {
    let now = Int64(Date().timeIntervalSince1970)
    var expiredTime: Int64 = 0

    override func setUp() {
        super.setUp()

        expiredTime = now - TokenStore.tokenExpirationSeconds - 60
    }

    func test_initFromString_v1() {
        let pushNotificationData = "old-v1-token"

        let ts = TokenStore()
        ts.loadEntries(fromStoredData: pushNotificationData)
        XCTAssertTrue(ts.isModified)
        XCTAssertEqual(ts.entries.count, 1)
        XCTAssertEqual("old-v1-token", ts.entries.first?.token)
        XCTAssertTrue(abs(ts.entries.first!.addedAt - now) < 5)

        let json = try? JSONEncoder().encode(ts)
        print("json: \(String(data: json!, encoding: .utf8)!)")
        print("stop here")
    }
}
