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

    // Case: decoding an object having 9 fields given an array of only 8 elements.
    // The result should be an OSRFObject with the last field omitted.
    func test_decode_shortObject() {
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
        XCTAssertNil(jsonArray[0])
        XCTAssertEqual("t", jsonArray[1] as? String)
        XCTAssertEqual(jsonArray.count, 8)

        let expectedObj = OSRFObject(["children": nil, "can_have_users": "t", "can_have_vols": "t",
                                      "depth": 3, "id": 11, "name": "Non-member Library",
                                      "opac_label": "Non-member Library", "parent": 10])
        do {
            let decodedObj = try OSRFCoder.decode("aout", wireString: wireString)
            debugPrint(decodedObj)
            XCTAssertEqual(decodedObj, expectedObj)
            XCTAssertEqual(decodedObj.dict.keys.count, 8)
        } catch {
            debugPrint(error)
            XCTFail(String(describing: error))
        }
    }
}
