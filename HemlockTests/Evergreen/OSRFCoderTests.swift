//
//  OSRFRegistryTests.swift
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
@testable import Hemlock

class OSRFCoderTests: XCTestCase {
    
    var payload: [Any?]?
    
    override func setUp() {
        OSRFCoder.clear()
    }
    
    func test_register() {
        OSRFCoder.registerClass("aout", fields: ["children","can_have_users","can_have_vols","depth","id","name","opac_label","parent","org_units"])
        
        var coder = OSRFCoder.findClass("xyzzy")
        XCTAssertNil(coder)
        
        coder = OSRFCoder.findClass("aout")
        XCTAssertEqual(coder?.netClass, "aout")
        XCTAssertEqual(coder?.fields.count, 9)
    }

    func test_decode_basic() {
        OSRFCoder.registerClass("aout", fields: ["children","can_have_users","can_have_vols","depth","id","name","opac_label","parent","org_units"])
        
        let coder = OSRFCoder.findClass("aout")
        XCTAssertEqual(coder?.netClass, "aout")
        XCTAssertEqual(coder?.fields.count, 9)
        
        let wireString = """
            [null,"t","t",3,11,"Non-member Library","Non-member Library",10]
            """
        guard
            let data = wireString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonArray = json as? [Any?] else
        {
            XCTFail("unable to decode json string as array")
            return
        }
        let first = jsonArray[0]
        if first == nil {
            print("ok but how")
        } else {
            print("ok but now I'm really confused")
        }
        XCTAssertNil(jsonArray[0])

        let decodedObj = OSRFCoder.decode("aout", wireString: wireString)
        debugPrint(decodedObj ?? "??")
        let expectedObj = OSRFObject(["children": nil, "can_have_users": true, "can_have_vols": true,
                                      "depth": 3, "id": 11, "name": "Non-member Library",
                                      "opac_label": "Non-member Library", "org_units": 10])
        XCTAssertEqual(decodedObj, expectedObj)
    }
}
