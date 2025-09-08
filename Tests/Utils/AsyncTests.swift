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

    static var serviceData = TestServiceData()

    override class func setUp() {
        super.setUp()

        serviceData = TestServiceData.make(fromBundle: Bundle(for: AsyncTests.self))
    }

    func test_asyncBasic() async throws {
        print("a\(Utils.tt) test_asyncBasic: start")
        let val = try await randomSleep("req")
        print("a\(Utils.tt) test_asyncBasic: val=\(val)")
        XCTAssertNotEqual("", val)
    }

    /// Use async-let to run two tasks in parallel, then await both
    func test_awaitTwoInParallel() async throws {
        print("a\(Utils.tt) test_awaitTwoInParallel: start")
        async let val1 = randomSleep("req1")
        async let val2 = randomSleep("req2")
        let (result1, result2) = try await (val1, val2)
        print("a\(Utils.tt) test_awaitTwoInParallel: val1=\(result1) val2=\(result2)")
        XCTAssertNotEqual("", result1)
        XCTAssertNotEqual("", result2)
    }

    func test_awaitTwoSequentially() async throws {
        print("a\(Utils.tt) test_awaitTwoSequentially: start")
        let val1 = try await randomSleep("req1")
        let val2 = try await randomSleep("req2")
        print("a\(Utils.tt) test_awaitTwoSequentially: val1=\(val1) val2=\(val2)")
        XCTAssertNotEqual("", val1)
        XCTAssertNotEqual("", val2)
    }

    func test_awaitGroup() async throws {
        print("a\(Utils.tt) test_awaitGroup: start")
        let numRequests = 5
        let results = try await withThrowingTaskGroup(of: String.self) { group -> [String] in
            for i in 0..<numRequests {
                group.addTask {
                    return try await self.randomSleep("\(i)")
                }
            }
            var combinedResults: [String] = []
            for try await result in group {
                combinedResults.append(result)
            }
            return combinedResults
        }
        print("a\(Utils.tt) test_awaitGroup: got \(results.count) results")
        XCTAssertEqual(numRequests, results.count)
    }

    // Use async-let to run two network requests in parallel, then await both
    func test_awaitParallel() async throws {
        let req1 = Gateway.makeRequest(url: randomDelayUrl(), shouldCache: false)
        let req2 = Gateway.makeRequest(url: randomDelayUrl(), shouldCache: false)

        async let data1Future = req1.gatewayDataResponseAsync()
        print("a\(Utils.tt) test_awaitParallel: data1 started")
        async let data2Future = req2.gatewayDataResponseAsync()
        print("a\(Utils.tt) test_awaitParallel: data2 started")

        let (data1, data2) = try await (data1Future, data2Future)

        let url1 = JSONUtils.parseObject(fromData: data1)?["url"] as? String ?? ""
        print("a\(Utils.tt) test_awaitParallel: url1=\(url1)")
        let url2 = JSONUtils.parseObject(fromData: data2)?["url"] as? String ?? ""
        print("a\(Utils.tt) test_awaitParallel: url2=\(url2)")
    }

    // This surprised me: using .asString() in the async-let does not defeat the parallelism
    func test_awaitParallelTake2() async throws {
        let req1 = Gateway.makeRequest(url: randomDelayUrl(), shouldCache: false)
        let req2 = Gateway.makeRequest(url: randomDelayUrl(), shouldCache: false)

        async let str1Future = req1.gatewayDataResponseAsync().asString()
        print("a\(Utils.tt) test_awaitParallelTake2: data1 started")
        async let str2Future = req2.gatewayDataResponseAsync().asString()
        print("a\(Utils.tt) test_awaitParallelTake2: data2 started")

        let (str1, str2) = try await (str1Future, str2Future)

        let url1 = JSONUtils.parseObject(fromStr: str1 ?? "")?["url"] as? String ?? ""
        print("a\(Utils.tt) test_awaitParallelTake2: url1=\(url1)")
        let url2 = JSONUtils.parseObject(fromStr: str2 ?? "")?["url"] as? String ?? ""
        print("a\(Utils.tt) test_awaitParallelTake2: url2=\(url2)")
    }

    // Yet another variation, using .asString() in the await
    func test_awaitParallelTake3() async throws {
        let req1 = Gateway.makeRequest(url: randomDelayUrl(), shouldCache: false)
        let req2 = Gateway.makeRequest(url: randomDelayUrl(), shouldCache: false)

        async let resp1 = req1.gatewayDataResponseAsync()
        print("a\(Utils.tt) test_awaitParallelTake3: resp1 bound")
        async let resp2 = req2.gatewayDataResponseAsync()
        print("a\(Utils.tt) test_awaitParallelTake3: resp2 bound")

        let (str1, str2) = try await (resp1.asString(), resp2.asString())

        let url1 = JSONUtils.parseObject(fromStr: str1 ?? "")?["url"] as? String ?? ""
        print("a\(Utils.tt) test_awaitParallelTake3: url1=\(url1)")
        let url2 = JSONUtils.parseObject(fromStr: str2 ?? "")?["url"] as? String ?? ""
        print("a\(Utils.tt) test_awaitParallelTake3: url2=\(url2)")
    }

    func randomDelayUrl() -> String {
        let delayTimeInMs = Int.random(in: 100..<1000)
//        let delayTimeInMs = Int.random(in: 2000..<9000)
        let delayTime = String(format: "%.3f", Float(delayTimeInMs) / 1000.0)
        let url = AsyncTests.serviceData.httpbinServerURL(path: "/delay/\(delayTime)")
        return url
    }

    func randomSleep(_ label: String) async throws -> String {
        let sleepTime = Int.random(in: 100..<1000)
        print("a\(Utils.tt) randomSleep: \(label) sleep for \(sleepTime) ms")
        try await Task.sleep(nanoseconds: UInt64(sleepTime) * 1_000_000)
        print("a\(Utils.tt) randomSleep: \(label) woke up after \(sleepTime) ms")
        return "\(sleepTime)ms"
    }
}

extension Data {
    func asString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
