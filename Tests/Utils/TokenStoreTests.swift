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

    /// true if the timestamp is within a few seconds of now, to allow for some slop in testing.
    /// Will fail if you stop in the debugger.
    func timeIsApproximatelyNow(_ timestamp: Int64) -> Bool {
        return abs(timestamp - now) < 5
    }

    func test_base64url_encodingIsCompatible() {
        // Check that the implementation we are using is compatible with other implementations,
        // that is, base64-url-encoding with no padding.
        let json = """
            {"a":"??~"}
            """
        let want = "eyJhIjoiPz9-In0" // plain base64 would be "eyJhIjoiPz9+In0="

        let encoded = json.encodeToBase64URL()
        XCTAssertEqual(want, encoded)

        let decoded = encoded.decodeFromBase64URL()
        XCTAssertEqual(json, decoded)
    }

    func test_base64url_decodeFromInvalid() {
        let input = "x"
        let decoded = input.decodeFromBase64URL()
        XCTAssertNil(decoded)
    }

    func test_initFromString_v1() {
        let pushNotificationData = "old-v1-token"

        let ts = TokenStore()
        ts.loadEntries(fromStoredData: pushNotificationData)
        XCTAssertTrue(ts.isModified)
        XCTAssertEqual(ts.entries.count, 1)
        XCTAssertEqual("old-v1-token", ts.entries.first?.token)
        XCTAssertTrue(timeIsApproximatelyNow(ts.entries.first!.addedAt))

        let json = try? JSONEncoder().encode(ts)
        print("json: \(String(data: json!, encoding: .utf8)!)")
        print("stop here")
    }
}
