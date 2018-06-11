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
    
    func test_failed_badJSON() {
        let json = """
            xyzzy
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertNotNil(resp.error)
    }
    
    func test_failed_noStatus() {
        let json = """
            {}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertNotNil(resp.error)
    }
    
    func test_failed_badStatus() {
        let json = """
            {"status":404}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertNotNil(resp.error)
    }
    
    func test_degenerateResponse() {
        let json = """
            {"payload":[[]],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.type, .array)
        XCTAssertEqual(resp.arrayResult?.count, 0)
    }

    func test_authInitResponse() {
        let json = """
            {"payload":["nonce"],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.stringResult, "nonce")
    }
    
    func test_authCompleteFailed() {
        let json = """
            {"payload":[{"ilsevent":1000,"textcode":"LOGIN_FAILED","desc":"User login failed"}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.obj?.getString("textcode"), "LOGIN_FAILED")
    }
    
    func test_actorCheckedOut() {
        let json = """
            {"status":200,"payload":[{"overdue":[],"out":["73107615","72954513"],"lost":[1,2]}]}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))

        // we can treat "out" as a list of Any
        guard let out = resp.obj?.getAny("out") as? [Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual(out.count, 2)

        // or as a list of IDs
        XCTAssertEqual(resp.obj?.getIntList("out"), [73107615, 72954513])
        XCTAssertEqual(resp.obj?.getIntList("overdue"), [])
        XCTAssertEqual(resp.obj?.getIntList("lost"), [1,2])
    }

}
