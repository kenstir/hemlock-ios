//
//  GatewayResponseTests.swift
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
import Foundation
@testable import Hemlock

class GatewayResponseTests: XCTestCase {
    
    func decodeJSON(_ jsonString: String) -> [String: Any]? {
        if
            let data = jsonString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let map = jsonObject as? [String: Any]
        {
            return map
        } else {
            return nil
        }
    }
    
    func createGatewayResponse(_ json: [String: Any]) -> GatewayResponse {
        let resp = GatewayResponse(json)
        return resp
    }
    
    func test_failed_noStatusResponse() {
        guard let map = decodeJSON("""
            {}
            """) else
        {
            XCTFail()
            return
        }
        let resp = GatewayResponse(map)
        XCTAssertTrue(resp.failed)
        XCTAssertNotNil(resp.error)
    }
    
    func test_degenerateResponse() {
        guard let map = decodeJSON("""
            {"payload":[[]],"status":200}
            """) else
        {
            XCTFail()
            return
        }
        let resp = GatewayResponse(map)
        XCTAssertEqual(resp.status, 200)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertNil(resp.payloadString)
        XCTAssertEqual(resp.payloadObject?.count, 0)
    }
    
    func test_authInitResponse() {
        guard let map = decodeJSON("""
            {"payload":["nonce"],"status":200}
            """) else
        {
            XCTFail()
            return
        }
        let resp = GatewayResponse(map)
        debugPrint(map)
        debugPrint(resp)
        XCTAssertEqual(resp.status, 200)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.payloadString, "nonce")
        XCTAssertNil(resp.payloadObject)
    }
    
    func test_authCompleteFailed() {
        guard let map = decodeJSON("""
            {"payload":[{"ilsevent":1000,"textcode":"LOGIN_FAILED","desc":"User login failed"}],"status":200}
            """) else
        {
            XCTFail()
            return
        }
        let resp = GatewayResponse(map)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.getString("textcode"), "LOGIN_FAILED")
    }
    
    func test_actorCheckedOut() {
        guard let map = decodeJSON("""
            {"status":200,"payload":[{"overdue":[],"out":["73107615","72954513"],"lost":[1,2]}]}
            """) else
        {
            XCTFail()
            return
        }
        let resp = GatewayResponse(map)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertNotNil(resp.payloadObject)
        guard let out = resp.getObject("out") as? [Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual(out.count, 2)
        XCTAssertEqual(resp.getListOfIDs("overdue"), [])
        XCTAssertEqual(resp.getListOfIDs("out"), [73107615, 72954513])
        XCTAssertEqual(resp.getListOfIDs("lost"), [1,2])
    }
}
