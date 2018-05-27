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
    var account: Account?
    var username = "" //read from testAccount.json
    var password = "" //read from testAccount.json
    var authtoken: String?
    
    //MARK: - functions
    
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
        Gateway.library = Library(url)
        account = Account(username, password: password)
    }

    //MARK: - LoginController Tests

    func test_LoginController_success() {
        let expectation = XCTestExpectation(description: "async response")
        LoginController(for: account!).login { resp in
            XCTAssertFalse(resp.failed, String(describing: resp.error))
            XCTAssertNotNil(self.account?.authtoken)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_LoginController_failure() {
        let expectation = XCTestExpectation(description: "async response")
        let altAccount = Account(username, password: "bogus")
        LoginController(for: altAccount).login { resp in
            XCTAssertTrue(resp.failed, String(describing: resp.error))
            XCTAssertNil(altAccount.authtoken)
            XCTAssertNotNil(resp.error)
            XCTAssertEqual(resp.errorMessage, "User login failed")

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_LoginController_getSession() {
        let parser = IDLParser(contentsOf: Gateway.idlURL()!)
        let ok = parser.parse()
        XCTAssertTrue(ok)

        let expectation = XCTestExpectation(description: "async response")
        LoginController(for: account!).login { resp in
            XCTAssertFalse(resp.failed, String(describing: resp.error))
            XCTAssertNotNil(self.account?.authtoken)
            LoginController.getSession(self.account!) { resp in
                debugPrint(resp)
                for key in (resp.obj?.dict.keys)! {
                    let val = resp.obj?.dict[key]
                    print("\(key) -> \(String(describing: val))")
                }
                let deleted = resp.obj?.getBool("deleted")
                XCTAssertFalse(deleted!)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - IDL
    
    func test_parseIDL_subset() {
        //let expectation = XCTestExpectation(description: "async response")
        self.measure {
            let url = Gateway.idlURL()
            let parser = IDLParser(contentsOf: url!)
            let ok = parser.parse()
            XCTAssertTrue(ok)
            XCTAssertGreaterThan(OSRFCoder.registryCount(), 1)
        }
    }
    
    //MARK: - actorCheckedOut
    
    /* Can't enable this test until we have IDL for the au class
    func test_actorCheckedOut_basic() {
        let expectation = XCTestExpectation(description: "async response")
        LoginController(for: account!).login { resp in
            guard let authtoken = self.account?.authtoken,
                let userID = self.account?.userID else
            {
                XCTFail()
                expectation.fulfill()
                return
            }
            let request = Gateway.createRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userID])
            request.responseData { response in
                print("response: \(response.description)")
                XCTAssertTrue(response.result.isSuccess)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    */
}
