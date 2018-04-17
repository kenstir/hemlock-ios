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
    
    func test_degenerate() {
        if
            let map = decodeJSON("{\"payload\":[[]],\"status\":200}"),
            let status = map["status"] as? Int
        {
            XCTAssertEqual(status, 200)
        } else {
            XCTFail()
        }

        //        let r = GatewayResponse(responseJSON)
//        XCTAssertEqual(r.status, 200)
//        XCTAssertEqual(r.payload, [])
    }
    
}
