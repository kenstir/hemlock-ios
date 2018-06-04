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
        
//            debugPrint(rsp)
//            let (json, response) = arg
//            print("json:     \(json)")
//            print("response: \(response)")
//        }.catch{ error in
//            showAlert(error)
//        }.finally {
//            expectation.fulfill()
//        }
        //            .responseJSON().then { json, response in
        //                print("json:     \(json)")
        //                print("response: \(response)")
        //            }.catch{ error in
        //                showAlert(error)
        //            }.finally {
        //                expectation.fulfill()
        //        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
