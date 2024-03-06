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
import Foundation
@testable import Hemlock

class AlamoTests: XCTestCase {
    let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)

    func test_basicGet() {
        let expectation = XCTestExpectation(description: "async response")
        let request = AF.request("https://httpbin.org/get")
        print("request:  \(request.description)")
        request.responseData { response in
            print("response: \(response.description)")
            switch response.result {
            case .success(let data):
                XCTAssertNotNil(data)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
 
        wait(for: [expectation], timeout: 10.0)
    }

    // use responseData to get response as Data then decode it as JSON
    func test_responseData() {
        let expectation = XCTestExpectation(description: "async response")
        let request = AF.request(App.directoryURL)
        print("request:  \(request.description)")
        request.responseData { response in
            print("response: \(response.description)")
            switch response.result {
            case .success(let data):
                XCTAssertNotNil(data)
                if let json = try? JSONSerialization.jsonObject(with: data)
                {
                    debugPrint(json)
                    XCTAssertTrue(json is [Any], "is array");
                    XCTAssertTrue(json is Array<Dictionary<String,Any>>, "is array of dictionaries");
                    XCTAssertTrue(json is [[String: Any]], "is array of dictionaries"); //shorthand
                    if let libraries = json as? [[String: Any]] {
                        for library in libraries {
                            let lib: [String: Any] = library
                            debugPrint(lib)
                            if let lat = lib["latitude"] as? Double, let longitude = lib["longitude"] as? Double {
                                debugPrint((lat,longitude))
                            }
                        }
                    }
                } else {
                    XCTFail()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

    // test using gatewayEncoding to encode as param=1&param=2
    func test_gatewayEncoding() {
        let url = URL(string: "https://httpbin.org/get")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        let parameters: Parameters = ["param": [1,2]]
        if let encodedURLRequest = try? gatewayEncoding.encode(urlRequest, with: parameters),
            let data = encodedURLRequest.httpBody,
            let str = String(data: data, encoding: .utf8) {
            XCTAssertEqual(str, "param=1&param=2")
        } else {
            XCTFail("getting httpBody as string")
        }
    }

    // make a request using gatewayEncoding
    func test_gatewayEncodingResponse() {
        let expectation = XCTestExpectation(description: "async response")
        let parameters = ["param": ["\"stringish\"", "{\"objish\":1}"]]
        let request = AF.request("https://httpbin.org/post", method: .post, parameters: parameters, encoding: gatewayEncoding)
        print("request:  \(request.description)")
        request.responseData { response in
            print("response: \(response.description)")
            switch response.result {
            case .success(let data):
                XCTAssertNotNil(data)
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let jsonObj = json as? [String: Any],
                   let form = jsonObj["form"] as? [String: Any],
                   let params = form["param"] as? [String]
                {
                    print(json)
                    print(form)
                    XCTAssertEqual(params[0], "\"stringish\"")
                    XCTAssertEqual(params[1], "{\"objish\":1}")
                    expectation.fulfill()
                } else {
                    XCTFail("validating form in json response")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_requestWithCache() {
        self.measure {
            let expectation = XCTestExpectation(description: "async response")
            let request = Gateway.makeRequest(url: "https://httpbin.org/ip", shouldCache: true)
            print("request:  \(request.description)")
            request.responseData { response in
                print("response: \(response.description)")
                switch response.result {
                case .success(let data):
                    XCTAssertNotNil(data)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }

    func test_requestWithoutCache() {
        self.measure {
            let expectation = XCTestExpectation(description: "async response")
            let request = Gateway.makeRequest(url: "https://httpbin.org/headers", shouldCache: false)
            print("request:  \(request.description)")
            request.responseData { response in
                print("response: \(response.description)")
                switch response.result {
                case .success(let data):
                    XCTAssertNotNil(data)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
}
