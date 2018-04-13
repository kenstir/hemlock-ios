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
    
    func test_basicGet() {
        Alamofire.request(API.librariesURL).responseJSON { response in
            print("Request: \(String(describing: response.request))")
            print("Response: \(String(describing: response.response))")
            print("Result: \(response.result)")
            
            XCTAssertTrue(response.result.isSuccess)
            
            guard let json = response.result.value else {
                XCTFail("no result value")
                return
            }
            print("JSON: \(json)") // serialized json response

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
