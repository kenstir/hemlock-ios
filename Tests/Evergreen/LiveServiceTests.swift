//
//  LoginControllerTests.swift
//  HemlockTests
//
//  Created by Ken Cox on 4/21/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import XCTest
@testable import Hemlock

/// These tests run against the live service configured in testAccount.json.
/// Don't do anything crazy here.
class LiveServiceTests: XCTestCase {
    
    let configFile = "TestUserData/testAccount" // .json
    var username = "" //read from testAccount.json
    var password = "" //read from testAccount.json
    
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
            XCTFail("unable to read JSON data from \(configFile).json, see TestUserData/README.md")
            return
        }
        API.library = Library(url)
        self.username = username
        self.password = password
    }
    
    //MARK: - LoginController Tests
    
    func test_LoginController_success() {
        let expectation = XCTestExpectation(description: "wait for async request")
        LoginController(username: username, password: password).login { account, resp in
            
            XCTAssertFalse(resp.failed, String(describing: resp.error))
            XCTAssertEqual(account.username, self.username)
            XCTAssertNotNil(account.authtoken)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_LoginController_failure() {
        let expectation = XCTestExpectation(description: "wait for async request")
        LoginController(username: username, password: "bogus").login { account, resp in
            
            XCTAssertTrue(resp.failed, String(describing: resp.error))
            XCTAssertEqual(account.username, self.username)
            XCTAssertNil(account.authtoken)
            
            XCTAssertNotNil(resp.error)
            let msg = resp.errorMessage
            XCTAssertEqual(msg, "User login failed")

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
}
