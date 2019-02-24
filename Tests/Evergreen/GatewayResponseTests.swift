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
    
    func test_authCompleteSuccess() {
        let json = """
            {"payload":[{"ilsevent":0,"textcode":"SUCCESS","desc":"Success","pid":6939,"stacktrace":"oils_auth.c:634","payload":{"authtoken":"985cda3d943232fbfd987d85d1f1a8af","authtime":420}}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.obj?.getString("textcode"), "SUCCESS")
        XCTAssertEqual(resp.obj?.getString("desc"), "Success")
        let payload = resp.obj?.getObject("payload")
        XCTAssertEqual(payload?.getInt("authtime"), 420)
    }

    func test_authCompleteFailed() {
        let json = """
            {"payload":[{"ilsevent":1000,"textcode":"LOGIN_FAILED","desc":"User login failed"}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, "User login failed")
    }
    
    func test_renewFailed() {
        let json = """
            {"payload":[{"ilsevent":"7008","servertime":"Sun Jul  1 23:15:38 2018","pid":22531,"desc":" Circulation has no more renewals remaining ","textcode":"MAX_RENEWALS_REACHED","stacktrace":"/usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:3701 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:274 /usr/local/share/perl/5.22.1/OpenSRF/Application.pm:628"}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, " Circulation has no more renewals remaining ")
    }
    
    func test_renewFailedForTwoReasons() {
        let json = """
            {"payload":[[{"payload":{"fail_part":"asset.copy_location.circulate"},"stacktrace":"/usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:1293 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4082 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4034","desc":" Target copy is not allowed to circulate ","ilsevent":"7003","textcode":"COPY_CIRC_NOT_ALLOWED","servertime":"Sat Feb 23 20:55:17 2019","pid":17822},{"payload":{"fail_part":"PATRON_EXCEEDS_FINES"},"pid":17822,"ilsevent":"7013","servertime":"Sat Feb 23 20:55:17 2019","textcode":"PATRON_EXCEEDS_FINES","stacktrace":"/usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:1293 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4082 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4034","desc":"The patron in question has reached the maximum fine amount"}]],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, " Target copy is not allowed to circulate ")
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
        XCTAssertEqual(resp.obj?.getIDList("out"), [73107615, 72954513])
        XCTAssertEqual(resp.obj?.getIDList("overdue"), [])
        XCTAssertEqual(resp.obj?.getIDList("lost"), [1,2])
    }

    func test_withNullValue() {
        let json = """
            {"payload":[{"children":null}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        guard let obj = resp.obj else {
            XCTFail()
            return
        }
        if let children = obj.dict["children"] {
            XCTAssertNil(children)
        } else {
            XCTFail()
        }
    }
    
    func test_copyLocationCounts() {
        let json = """
            {"payload":[[["280","","782.2530973 AMERICAN","","Adult",{"1":1}]]],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.type, .unknown)
        guard let payload = resp.payload,
            let payloadArray = payload as? [Any],
            let first = payloadArray.first as? [Any],
            let counts = first.first as? [Any] else
        {
            XCTFail()
            return
        }
        XCTAssertEqual(payloadArray.count, 1)
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(counts.count, 6)
    }
}
