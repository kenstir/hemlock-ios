//
//  AlamoTests.swift
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
import Alamofire
@testable import Hemlock

class AlamoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func printInfo(_ name: String, _ value: Any) {
        let t = type(of: value)
        print("\(name) has type \(t)")
    }

    func test_basicGet() {
        let request = Alamofire.request(API.directoryURL)

        debugPrint(request)
        request.responseJSON { response in
            print("Request: \(String(describing: response.request))")
            print("Response: \(String(describing: response.response))")
            print("Result: \(response.result)")
            self.printInfo("response.result", response.result);

            XCTAssertTrue(response.result.isSuccess)
            
            XCTAssertTrue(response.result.value != nil, "result has value")
            guard let json = response.result.value else {
                return
            }
            self.printInfo("json", json);
            debugPrint(json)

            XCTAssertTrue(json is [Any], "is array");
            XCTAssertTrue(json is Array<Dictionary<String,Any>>, "is array of dictionaries");
            XCTAssertTrue(json is [[String: Any]], "is array of dictionaries"); //shorthand
            guard let libraries = response.result.value as? [[String: Any]] else {
                return
            }
            for library in libraries {
                let lib: [String: Any] = library
                debugPrint(lib)
            }
        }
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
