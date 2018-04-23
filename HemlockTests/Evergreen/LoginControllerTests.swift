//
//  LoginControllerTests.swift
//  HemlockTests
//
//  Created by Ken Cox on 4/21/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import XCTest
@testable import Hemlock

class LoginControllerTests: XCTestCase {
    
    let configFile = "TestConfig/testAccount" // .json
    var username = "read from testAccount.json"
    var password = "read from testAccount.json"
    
    override func setUp() {
        super.setUp()
        
        // read configFile as json
        let testBundle = Bundle(for: type(of: self))
        guard
            let path = testBundle.path(forResource: configFile, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: String],
            let url = jsonObject["url"],
            let username = jsonObject["username"],
            let password = jsonObject["password"] else
        {
            XCTFail("unable to read data from \(configFile).json, see TestConfig/README.md")
            return
        }
        API.library = Library(url)
        self.username = username
        self.password = password
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasic() {
        let expectation = XCTestExpectation(description: "wait for async request")
        LoginController(username: username, password: password).login { account, resp in
            
            XCTAssertEqual(account.username, self.username)
            XCTAssertFalse(resp.failed, String(describing: resp.error))

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 240.0)
    }
}
