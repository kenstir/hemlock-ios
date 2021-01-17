//
//  MiscTests.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
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
@testable import Hemlock

/// This class exists to evaluate random questions relating to Swift.
/// The error messages are better here than in the Swift playground.
class MiscTests: XCTestCase {
    
    // Test how to deserialize from JSON
    func test_howto_deserializeJSON() {
        let str = """
            {"__c": "aout", "num": 42, "opt": null, "arr": [1,2,3]}
            """
        
        guard
            let data = str.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any?],
            let jsonObject2 = json as? [String: Any] else
        {
            XCTFail()
            return
        }
        
        debugPrint(jsonObject)
        debugPrint(jsonObject2)
        XCTAssertEqual(jsonObject["__c"] as? String, "aout")
        XCTAssertEqual(jsonObject["num"] as? Int, 42)
        XCTAssertEqual(jsonObject["arr"] as? [Int], [1,2,3])
        
        // If you coerce to [String: Any?], "opt" gets a value of nil
        if let optval = jsonObject["opt"] {
            print("obj[opt] is \(String(describing: optval))")
            XCTAssertNil(optval)
        } else {
            XCTFail()
        }

        // If you coerce to [String: Any], "opt" gets a value of NSNull
        if let optval = jsonObject2["opt"] {
            print("obj[opt] is \(optval)")
            XCTAssertTrue(optval is NSNull)
        } else {
            XCTFail()
        }
    }
    
    // Test how to serialize to JSON
    func test_howto_serializeJSON() {
        let dict: [String: Any?] = ["__c": "aout", "num": 42, "null": nil, "arr": [1,2,3]]
        if
            let jsonData = try? JSONSerialization.data(withJSONObject: dict),
            let str = String(data: jsonData, encoding: .utf8)
        {
            debugPrint(str)
            XCTAssertNotNil(str)
        } else {
            XCTFail()
        }
    }

    // Test that HemlockError can override the localizedDescription by conforming to LocalizedError
    func testHemlockError() {
        let err = HemlockError.unexpectedNetworkResponse("because")
        let desc = err.errorDescription
        print("desc: \(desc ?? "")")
        XCTAssertEqual("Unexpected network response: because", desc)
        
        let baseError = err as Error
        let baseDesc = baseError.localizedDescription
        print("base: \(baseDesc)")
        XCTAssertEqual("Unexpected network response: because", baseDesc)
    }
    
    func test_isSessionExpiredError() {
        let unexpectedError = HemlockError.unexpectedNetworkResponse("because")
        XCTAssertFalse(isSessionExpired(error: unexpectedError))
        
        let serverError = HemlockError.serverError("because")
        XCTAssertFalse(isSessionExpired(error: serverError))
        
        let hemlockSessionExpiredError = HemlockError.sessionExpired
        XCTAssertTrue(isSessionExpired(error: hemlockSessionExpiredError))
        
        let gwerr = GatewayError.event(ilsevent: 1001, textcode: "NO_SESSION", desc: "Login session has timed out or does not exist", failpart: nil)
        XCTAssertTrue(isSessionExpired(error: gwerr))
    }
    
    // Test ways to parse a date string
    func testDateParsing() {
        let apiDate = "2017-05-01T14:03:24-0400"

        // hard way
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let date1 = df.date(from: apiDate)

        // easy way
        let df2 = ISO8601DateFormatter()
        let date2 = df2.date(from: apiDate)

        XCTAssertEqual(date1, date2)
    }
    
    func testDateFormatting() {
        let apiDate = "2018-04-26T19:27:58-0400"
        let apiDateFormatter = ISO8601DateFormatter()
        let date = apiDateFormatter.date(from: apiDate)
        let str = apiDateFormatter.string(from: date!)
        XCTAssertEqual(str, "2018-04-26T23:27:58Z")

        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateStyle = .long
        outputDateFormatter.timeStyle = .none
        outputDateFormatter.locale = Locale(identifier: "en_US")
        let str2 = outputDateFormatter.string(from: date!)
        debugPrint(str2)
        XCTAssertEqual(str2, "April 26, 2018")
    }
    
    func testJoin() {
        let testArray = ["One","Two","Three","Four"]
        let joinedString = testArray.joined(separator: ",")
        XCTAssertEqual(joinedString, "One,Two,Three,Four")
    }
    
    func testStringRegexMatch() {
        let pattern = "^\\d{3}-\\d{3}-\\d{4}$"

        var phoneNumber = "123-456-7890"
        var range = phoneNumber.range(of: pattern, options: .regularExpression)
        XCTAssertTrue(range != nil)

        phoneNumber = "123"
        range = phoneNumber.range(of: pattern, options: .regularExpression)
        XCTAssertFalse(range != nil)
        
        phoneNumber = "123-456-78900"
        range = phoneNumber.range(of: pattern, options: .regularExpression)
        XCTAssertFalse(range != nil)
    }
    
    func test_appName() {
        XCTAssertEqual("Hemlock", Bundle.appName)
    }
    
    func test_appVersion() {
        XCTAssertNotEqual("?", Bundle.appVersion)
    }
    
    func test_isTestFlight() {
        XCTAssertTrue(Bundle.isTestFlightOrDebug)
    }
    
    func test_dumpAndCompactMap() {
        let d: JSONDictionary = [
            "a": nil,
            "b": 2,
            "c": "three",
        ]
        Utils.dump(dict: d)
        
        let values = d.map { $0.value }
        XCTAssertEqual(values.count, 3)
        let compactValues = d.compactMap { $0.value }
        XCTAssertEqual(compactValues.count, 2)
    }
    
    func test_bool_toString() {
        var a: Bool? = nil
        XCTAssertEqual(Utils.toString(a), "nil")
        a = true
        XCTAssertEqual(Utils.toString(a), "true")
    }
    
    func test_urlrequest_tag() {
        let qstring = "service=open-ils.pcrud&method=open-ils.pcrud.retrieve.mra&param=%22ANONYMOUS%22&param=6221645"
 
        let getRequest = try? URLRequest(url: "http://gapines.org/osrf-gateway-v1?\(qstring)", method: .get)
        var postRequest = try? URLRequest(url: "http://gapines.org/osrf-gateway-v1", method: .post)
        postRequest?.httpBody = qstring.data(using: .utf8)

        XCTAssertNotNil(getRequest)
        XCTAssertNotNil(postRequest)
        
        let getTag = getRequest?.debugTag
        let postTag = postRequest?.debugTag
        XCTAssertNotNil(getTag)
        XCTAssertEqual(getTag, postTag)
    }
}
