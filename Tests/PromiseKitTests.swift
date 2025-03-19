//
//  PromiseKitTests.swift
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
import PromiseKit
import PMKAlamofire
import Foundation
@testable import Hemlock

class PromiseKitTests: XCTestCase {
    let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)

    var serviceData = TestServiceData()

    override func setUp() {
        super.setUp()

        serviceData = TestServiceData.make(fromBundle: Bundle(for: type(of: self)))
    }

    func showAlert(_ error: Error) {
        let desc = error.localizedDescription
        print("ERROR: \(desc)")
    }

    func test_basicPromiseChain() {
        let expectation = XCTestExpectation(description: "async response")

        var savedResult: Any?

        let req = AF.request(serviceData.httpbinServerURL())
        req.responseJSON().done { json in
            print("done: \(json)")
            savedResult = json
        }.ensure {
            print("ensure")
            expectation.fulfill()
        }.catch { error in
            print("error")
            self.showAlert(error)
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertNotNil(savedResult)
    }

    func test_promiseChainDoneDone() {
        let expectation = XCTestExpectation(description: "async response")

        var doneCount = 0

        let promise = after(seconds: 0.1)
        promise.done {
            doneCount += 1
        }.done {
            doneCount += 1
        }.ensure {
            expectation.fulfill()
        }.catch { error in
            self.showAlert(error)
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(2, doneCount)
    }

    // Test to make sure I understood how to exit a promise chain early.
    // If you throw your own error, you can handle it in 'catch',
    // if you throw PMKError.cancelled then 'catch' does not fire.
    func test_cancelPromiseChain() {
        let expectation = XCTestExpectation(description: "async response")

        var stage = 0
        var req: Alamofire.DataRequest
        var parameters: [String: Any]

        parameters = ["stage": stage]
        req = AF.request(serviceData.httpbinServerURL(), method: .get, parameters: parameters)
        req.responseJSON().then { (json: Any, response: PMKAlamofire.PMKAlamofireDataResponse) -> Promise<(json: Any, response: PMKAlamofire.PMKAlamofireDataResponse)> in
            stage = 1
            print("stage \(stage)")
            if stage > 0 {
                throw PMKError.cancelled
            }
            parameters = ["stage": stage]
            req = AF.request(self.serviceData.httpbinServerURL(), method: .get, parameters: parameters)
            return req.responseJSON()
        }.then { (json: Any, response: PMKAlamofire.PMKAlamofireDataResponse) -> Promise<(json: Any, response: PMKAlamofire.PMKAlamofireDataResponse)> in
            stage = 2
            print("stage \(stage)")
            parameters = ["stage": stage]
            req = AF.request(self.serviceData.httpbinServerURL(), method: .get, parameters: parameters)
            return req.responseJSON()
        }.done { json in
            stage = 3
            print("stage \(stage)")
        }.ensure {
            print("ensure")
            expectation.fulfill()
        }.catch { error in
            print("error")
            self.showAlert(error)
        }
        
        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(stage, 1)
    }

    // verify that when JSON decoding fails we catch an error
    func test_jsonErrorInPromiseChain() {
        let expectation = XCTestExpectation(description: "async response")
        
        var errorCount = 0

        // this url returns xml
        let req = AF.request(serviceData.httpbinServerURL(path: "/xml"))
        req.responseJSON().done { json in
            print("done: \(json)")
            expectation.fulfill()
        }.ensure {
            print("ensure")
        }.catch { error in
            print("error")
            self.showAlert(error)
            errorCount = errorCount + 1
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(1, errorCount)
    }

    // run multiple promise chains independently
    func test_parallelPromiseChains() {
        var expectations: [XCTestExpectation] = []
        
        for i in 0...9 {
            let expectation = XCTestExpectation(description: "\(i): response")
            expectations.append(expectation)

            let params = ["i": i]
            let req = AF.request(serviceData.httpbinServerURL(), method: .get, parameters: params)
            print("\(i): req")
            req.responseJSON().done { json in
                print("\(i): done")
            }.ensure {
                print("\(i): ensure")
                expectation.fulfill()
            }.catch { error in
                print("\(i): error")
                self.showAlert(error)
            }
        }
        
        print("-: wait")
        wait(for: expectations, timeout: 10.0)
    }
    
    // Run multiple promise chains until 'done' then wait for them all with when(fulfilled:).
    // I like this pattern.
    func test_whenFulfilled() {
        var expectations: [XCTestExpectation] = []
        var promises: [Promise<Void>] = []
        
        for i in 0...9 {
            let expectation = XCTestExpectation(description: "\(i): response")
            expectations.append(expectation)

            let params = ["i": i]
            let req = AF.request(serviceData.httpbinServerURL(), method: .get, parameters: params)
            print("\(i): req")
            
            let promise = req.responseJSON().done { json in
                print("\(i): done")
            }.ensure {
                print("\(i): ensure")
                expectation.fulfill()
            }
            promises.append(promise)
        }

        print("-: when")
        firstly {
            when(fulfilled: promises)
        }.done {
            print("-: done")
        }.catch { error in
            print("-: error")
            self.showAlert(error)
        }
        
        print("-: wait")
        wait(for: expectations, timeout: 10)
    }
 
    // You can also fire off multiple requests and handle 'done' for all
    // promises together as an array of (json,response) tuples.
    func test_whenFulfilledDoneAllAtOnce() {
        var expectations: [XCTestExpectation] = []
        var promises: [Promise<(json: Any, response: PMKAlamofireDataResponse)>] = []
        
        for i in 0..<4 {
            let expectation = XCTestExpectation(description: "\(i): response")
            expectations.append(expectation)

            let params = ["i": i]
            let req = AF.request(serviceData.httpbinServerURL(), method: .get, parameters: params)
            print("\(i): req")
            
            let promise = req.responseJSON().ensure {
                print("\(i): ensure")
                expectation.fulfill()
            }
            promises.append(promise)
        }
        
        print("-: when")
        firstly {
            when(fulfilled: promises)
        }.done { tuples in
            print("-: done")
            for tuple in tuples {
                let (json, response) = tuple
                print("-: done " + (response.request!.url?.absoluteString)!)
                //debugPrint(json)
                if let dict = json as? [String: Any?],
                    let args = dict["args"] as? [String: Any?],
                    let arg_i = args["i"] as? String,
                    let i = Int(arg_i)
                {
                    print("\(i): done")
                }
            }
        }.catch { error in
            print("-: error")
            self.showAlert(error)
        }
        
        print("-: wait")
        wait(for: expectations, timeout: 10)
    }
}
