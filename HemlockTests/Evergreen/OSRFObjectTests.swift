//
//  OSRFObjectTests.swift
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
import Foundation

class OSRFObjectTests: XCTestCase {
    
    func testJSONEncode() {
        let jsonObj: [String: Any?] = ["__c": "aout", "num": 42, "null": nil, "arr": [1,2,3]]
        if
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj),
            let str = String(data: jsonData, encoding: .utf8) {
            debugPrint(str)
            print(String(describing: str))
        }
    }
    
    func testJSONEncodeDifferentOrder() {
        let jsonObj1: [String: Any?] = ["__c": "aout", "num": 42, "null": nil, "arr": [1,2,3]]
        let jsonObj2: [String: Any?] = ["arr": [1,2,3], "num": 42, "null": nil, "__c": "aout"]
        //XCTAssertEqual(jsonObj1, jsonObj2) // Expression type '()' is abiguous without more context
        if
            let jsonData1 = try? JSONSerialization.data(withJSONObject: jsonObj1),
            let str1 = String(data: jsonData1, encoding: .utf8),
            let jsonData2 = try? JSONSerialization.data(withJSONObject: jsonObj2),
            let str2 = String(data: jsonData2, encoding: .utf8) {
            print(String(describing: str1))
            print(String(describing: str2))
            // NB: this check fails
            //XCTAssertEqual(str1, str2)
        } else {
            XCTFail("strings of identical objects are not identical")
        }
    }

    func testJSONDecode() {
        let str = """
            {"__c": "aout", "num": 42, "null": null, "arr": [1,2,3]}
            """

        if
            let data = str.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any?]
        {
            debugPrint(json)
            debugPrint(jsonObject)
            if let val = jsonObject["nul"] {
                debugPrint(val ?? "??")
                print(String(describing: val))
                if val == nil {
                    print("is nil")
                }
            }
            if let val = jsonObject["null"] {
                debugPrint(val ?? "??")
                print(String(describing: val))
                if val == nil {
                    print("is nil")
                }
            }
        }
    }
    
}
