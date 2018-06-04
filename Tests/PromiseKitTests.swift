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
    
    func showAlert(_ error: Error) {
        debugPrint(error)
    }
    
    func test_basicGet() {
        let expectation = XCTestExpectation(description: "async response")
        
        let req = Alamofire.request("https://httpbin.org/get")
        req.responseJSON().done { json in
            print("json:     \(json)")
            }.catch { error in
                print("error!!!")
                self.showAlert(error)
            }.finally {
                print("finally")
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // run multiple promise chains independently
    func test_parallelPromiseChains() {
        var expectations: [XCTestExpectation] = []
        
        for i in 0...9 {
            let expectation = XCTestExpectation(description: "\(i): response")
            expectations.append(expectation)

            let params = ["i": i]
            let req = Alamofire.request("https://httpbin.org/get", method: .get, parameters: params)
            print("\(i): req")
            req.responseJSON().done { json in
                print("\(i): done")
            }.catch { error in
                print("\(i): error")
                self.showAlert(error)
            }.finally {
                print("\(i): finally")
                expectation.fulfill()
            }
        }
        
        print("-: wait")
        wait(for: expectations, timeout: 10.0)
    }
    
    // run multiple promise chains until 'done' then wait for them all with 'when'
    // I like this pattern
    func test_whenFulfilled() {
        var expectations: [XCTestExpectation] = []
        var promises: [Promise<Void>] = []
        
        for i in 0...9 {
            let expectation = XCTestExpectation(description: "\(i): response")
            expectations.append(expectation)

            let params = ["i": i]
            let req = Alamofire.request("https://httpbin.org/get", method: .get, parameters: params)
            print("\(i): req")
            
            let promise = req.responseJSON().done { json in
                print("\(i): done")
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
        }.finally {
            print("-: finally")
        }
        
        print("-: wait")
        wait(for: expectations, timeout: 10)
    }
 
    // You can also fire off multiple requests and handle 'done' for all
    // promises together as an array of (json,response) tuples.
    // I don't like this pattern for unit testing, because I have to associate
    // the response with the XCTestExpectation.  The test_whenFulfilled looks cleaner.
    func test_whenFulfilledDoneAllAtOnce() {
        var expectations: [XCTestExpectation] = []
        var expectationMap: [Int: XCTestExpectation] = [:]
        var promises: [Promise<(json: Any, response: PMKAlamofireDataResponse)>] = []
        
        for i in 0..<10 {
            let expectation = XCTestExpectation(description: "\(i): response")
            expectations.append(expectation)
            expectationMap[i] = expectation
            
            let params = ["i": i]
            let req = Alamofire.request("https://httpbin.org/get", method: .get, parameters: params)
            print("\(i): req")
            
            let promise = req.responseJSON()
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
                    expectationMap[i]?.fulfill()
                }
            }
        }.catch { error in
            print("-: error")
            self.showAlert(error)
        }.finally {
            print("-: finally")
        }
        
        print("-: wait")
        wait(for: expectations, timeout: 10)
    }
    
    //todo: single promise chain expecting json getting httpbin.org/xml
    //todo: parallel promise chains with http 404 error httpbin.org/not_found
}
