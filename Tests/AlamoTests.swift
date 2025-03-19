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

class TestServiceData {
    static let configFile = "TestUserData/testServiceData" // .json
    static var instance: TestServiceData? = nil

    let httpbinServer: String?

    init(httpbinServer: String?) {
        self.httpbinServer = httpbinServer
    }

    static func make(fromBundle bundle: Bundle) -> TestServiceData {
        if let i = instance {
            return i
        }

        // read json file
        guard let path = bundle.path(forResource: TestServiceData.configFile, ofType: "json") else {
            let i = TestServiceData(httpbinServer: "invalid JSON data in \(TestServiceData.configFile).json, see TestUserData/README.md")
            instance = i
            return i
        }
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any],
            let httpbinServer = jsonObject["httpbinServer"] as? String else
        {
            let i = TestServiceData(httpbinServer: "invalid JSON data in \(TestServiceData.configFile).json, see TestUserData/README.md")
            instance = i
            return i
        }
        let i = TestServiceData(httpbinServer: httpbinServer)
        instance = i
        return i
    }

    func httpbinServerURL(path: String? = nil) -> String {
        return (httpbinServer ?? "https://httpbin.org") + (path ?? "/get")
    }

    func httpbinServerPostURL() -> String {
        return httpbinServerURL(path: "/post")
    }

}

class AlamoTests: XCTestCase {
    let gatewayEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .numeric)

    var serviceData: TestServiceData?

    override func setUp() {
        super.setUp()

        serviceData = TestServiceData.make(fromBundle: Bundle(for: type(of: self)))
    }

    func test_basicGet() {
        let expectation = XCTestExpectation(description: "async response")
        let request = AF.request(serviceData!.httpbinServerURL())
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

    // fetch the libraries.json file from evergreen-ils.org and decode it
    func test_responseData() {
        let expectation = XCTestExpectation(description: "async response")
        let request = AF.request(App.directoryURL)
        print("request:  \(request.description)")
        request.responseData { response in
            print("response: \(response.description)")
            switch response.result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data),
                    let libraries = json as? [JSONDictionary] {
                    //debugPrint(json)
                    for library in libraries {
                        let name = JSONUtils.getString(library, key: "directory_name")
                        XCTAssertNotNil(name)
                        let url = JSONUtils.getString(library, key: "url")
                        XCTAssertNotNil(url)
                        print("name = \(name ?? ""), url = \(url ?? "")")
                    }
                } else {
                    XCTFail("unable to decode response as array of dict")
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
        let url = URL(string: serviceData!.httpbinServerURL())!
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
        let request = AF.request(serviceData!.httpbinServerPostURL(), method: .post, parameters: parameters, encoding: gatewayEncoding)
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
            let url = serviceData!.httpbinServerURL(path: "/ip")
            let request = Gateway.makeRequest(url: url, shouldCache: true)
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
            let url = serviceData!.httpbinServerURL(path: "/headers")
            let request = Gateway.makeRequest(url: url, shouldCache: false)
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

    // FAILED ATTEMPT TO VALIDATE CACHING
    //
    // So for now I validated caching by watching the request log on a local server.
    //
//    func randomString(length: Int) -> String {
//        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//        return String((0..<length).map{ _ in letters.randomElement()! })
//    }
//
//    // Send 2 requests with anything?rand=x, and expect both responses to echo the same 'rand' arg,
//    // and to have the same X-Amzn-Trace-Id, meaning that only one actual request made it to the server
//    // and the other was cached.
//    func test_requestWithCache() {
//        let randomArg = randomString(length: 8)
//        var expectedTraceID: String? = nil
//        for i in 1...2 {
//            let expectation = XCTestExpectation(description: "async response")
//            let url = "https://httpbin.org/anything?rand=\(randomArg)"
//            let request = Gateway.makeRequest(url: url, shouldCache: true)
//            request.responseData { response in
//                print("response: \(response.description)")
//                switch response.result {
//                case .success(let data):
//                    if let dict = JSONUtils.parseObject(fromData: data),
//                       let args = JSONUtils.getObj(dict, key: "args"),
//                       let responseRandArg = JSONUtils.getString(args, key: "rand"),
//                       let headers = JSONUtils.getObj(dict, key: "headers"),
//                       let responseTraceID = JSONUtils.getString(headers, key: "X-Amzn-Trace-Id")
//                    {
//                        XCTAssertEqual(randomArg, responseRandArg)
//                        print("traceID: \(responseTraceID)")
//                        if expectedTraceID == nil {
//                            expectedTraceID = responseTraceID
//                        } else {
//                            XCTAssertEqual(expectedTraceID, responseTraceID)
//                        }
//                    } else {
//                        XCTFail()
//                    }
//                case .failure(let error):
//                    XCTFail(error.localizedDescription)
//                }
//                expectation.fulfill()
//            }
//
//            wait(for: [expectation], timeout: 20.0)
//        }
//    }
}
