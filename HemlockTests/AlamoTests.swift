//
//  AlamoTests.swift
//  HemlockTests
//
//  Created by Ken Cox on 4/12/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

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
        let request = Alamofire.request(API.librariesURL)

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
            XCTAssertTrue(json is [[String: Any]], "is array of dictionaries");
            // [[String: Any]] is equivalent to Array<Dictionary<String,Any>>
            if let libraries = response.result.value as? [[String: Any]] {
                for library in libraries {
                    let lib: [String: Any] = library
                    debugPrint(lib)
                }
            } else {
                XCTFail("not array of [String:String]")
            }

//            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
//                print("Data: \(utf8Text)") // original server data as UTF8 string
//            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
