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
@testable import Hemlock

class AsyncTests: XCTestCase {
    func test_asyncBasic() async throws {
        print("a\(Utils.tt) test_asyncBasic: start")
        let val = await randomSleep("req")
        print("a\(Utils.tt) test_asyncBasic: val=\(val)")
        XCTAssertNotEqual("", val)
    }

    func test_awaitTwoInParallel() async throws {
        print("a\(Utils.tt) test_awaitTwoInParallel: start")
        async let val1 = randomSleep("req1")
        async let val2 = randomSleep("req2")
        let (result1, result2) = await (val1, val2)
        print("a\(Utils.tt) test_awaitTwoInParallel: val1=\(result1) val2=\(result2)")
        XCTAssertNotEqual("", result1)
        XCTAssertNotEqual("", result2)
    }

    func test_awaitTwoSequentially() async throws {
        print("a\(Utils.tt) test_awaitTwoSequentially: start")
        let val1 = await randomSleep("req1")
        let val2 = await randomSleep("req2")
        print("a\(Utils.tt) test_awaitTwoSequentially: val1=\(val1) val2=\(val2)")
        XCTAssertNotEqual("", val1)
        XCTAssertNotEqual("", val2)
    }

    func randomSleep(_ label: String) async -> String {
        let sleepTime = Int.random(in: 1000..<3000)
        print("a\(Utils.tt) randomSleep: \(label) sleep for \(sleepTime) ms")
        try? await Task.sleep(nanoseconds: UInt64(sleepTime) * 1_000_000)
        print("a\(Utils.tt) randomSleep: \(label) woke up after \(sleepTime) ms")
        return "\(sleepTime)ms"
    }
}
