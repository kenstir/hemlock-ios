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
        let expected = "eyJhIjoiPz9-In0" // plain base64 would be "eyJhIjoiPz9+In0="

        let encoded = json.encodeToBase64URL()
        XCTAssertEqual(encoded, expected)

        let decoded = encoded.decodeFromBase64URL()
        XCTAssertEqual(decoded, json)
    }

    func test_base64url_decodeFromInvalid() {
        let input = "x"
        let decoded = input.decodeFromBase64URL()
        XCTAssertNil(decoded)
    }

    func test_initFromString_v1() {
        let pushNotificationData = "old-v1-token"

        let ts = TokenStore()
        ts.initialize(fromString: pushNotificationData)
        XCTAssertTrue(ts.isModified)
        XCTAssertEqual(ts.entries.count, 1)
        XCTAssertEqual(ts.entries.first?.token, pushNotificationData)
        XCTAssertTrue(timeIsApproximatelyNow(ts.entries.first!.addedAt))
    }

    func test_initFromString_v1LooksLikeV2() {
        let pushNotificationData = TokenStore.v2EncodedTokenPrefix + "old-v1-token"

        let ts = TokenStore()
        ts.initialize(fromString: pushNotificationData)
        XCTAssertTrue(ts.isModified)
        XCTAssertEqual(ts.entries.count, 1)
        XCTAssertEqual(ts.entries.first?.token, pushNotificationData)
        XCTAssertTrue(timeIsApproximatelyNow(ts.entries.first!.addedAt))
    }

    func test_initFromString_empty() {
        let testData: [String?] = [nil, ""]
        for pushNotificationData in testData {
            let ts = TokenStore()
            ts.initialize(fromString: pushNotificationData)
            XCTAssertFalse(ts.isModified)
            XCTAssertTrue(ts.entries.isEmpty)
        }
    }

    func test_initFromString_v2() {
        // NB: the object keys are sorted to simplify testing
        let json = """
            {
                "entries": [
                    {"added_at": 1775060400, "token": "token-1"},
                    {"added_at": 1775060410, "token": "token-2"}
                ]
            }
            """.trimAllWhitespace()
        let encoded = json.encodeToBase64URL()

        let ts = TokenStore()
        ts.initialize(fromString: encoded)
        XCTAssertFalse(ts.isModified)
        XCTAssertEqual(ts.entries.count, 2)
        XCTAssertEqual(ts.entries[0].token, "token-1")
        XCTAssertEqual(ts.entries[0].addedAt, 1775060400)

        let reencoded = ts.encodeToString()
        XCTAssertEqual(reencoded, encoded)
    }

    func test_initFromString_removesExpiredToken() {
        let json = """
            {
                "entries": [
                    {"added_at": \(expiredTime), "token": "token-1"},
                    {"added_at": \(now), "token": "token-2"}
                ]
            }
            """.trimAllWhitespace()
        let encoded = json.encodeToBase64URL()

        let ts = TokenStore()
        ts.initialize(fromString: encoded)
        XCTAssertTrue(ts.isModified)
        XCTAssertEqual(ts.entries.count, 1)
        XCTAssertEqual(ts.entries[0].token, "token-2")
    }
}
