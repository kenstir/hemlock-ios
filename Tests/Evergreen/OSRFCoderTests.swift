//
//  OSRFCoderTests.swift
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
    
    //MARK: - methods

    override func setUp() {
        super.setUp()
        OSRFCoder.clearRegistry()
    }
    
    // Deserialize an array from JSON
    func deserializeJSONArray(_ wireString: String) -> [Any?]? {
        if let data = wireString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonArray = json as? [Any?] {
            return jsonArray
        } else {
            return nil
        }
    }
    
    // Deserialize a dictionary from JSON
    func deserializeJSONObject(_ wireString: String) -> [String: Any?]? {
        if let data = wireString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let dict = json as? [String: Any?] {
            return dict
        } else {
            return nil
        }
    }
    
    func deserializeJSONObjectArray(_ wireString: String) -> [[String: Any?]]? {
        if let data = wireString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonArray = json as? [[String: Any?]] {
            return jsonArray
        } else {
            return nil
        }
    }

    //MARK: - tests
    
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
        XCTAssertNotNil(coder)
        XCTAssertEqual(coder?.fields.count, 9)
        
        let wirePayload = """
            [null,"t","t",3,11,"Non-member Library","Non-member Library",10]
            """
        guard let jsonArray = deserializeJSONArray(wirePayload) else {
            XCTFail("ERROR decoding JSON")
            return
        }
        XCTAssertNil(jsonArray[0])
        XCTAssertEqual("t", jsonArray[1] as? String)
        XCTAssertEqual(jsonArray.count, 8)

        let expectedObj = OSRFObject(["children": nil, "can_have_users": "t", "can_have_vols": "t",
                                      "depth": 3, "id": 11, "name": "Non-member Library",
                                      "opac_label": "Non-member Library", "parent": 10])
        do {
            let decodedObj = try OSRFCoder.decode("aout", wirePayload: jsonArray)
            debugPrint(decodedObj)
            XCTAssertEqual(decodedObj, expectedObj)
            XCTAssertEqual(decodedObj.dict.keys.count, 8)
        } catch {
            debugPrint(error)
            XCTFail(String(describing: error))
        }
    }
    
    // Case: decoding an OSRF object from the wire protocol {"__c": netClass, "__p": [...]}
    func test_decode_wireObject() {
        OSRFCoder.registerClass("test", fields: ["can_haz_bacon","id","name"])
        
        let wireProtocol = """
            {"__c":"test","__p":["t",1,"Hormel"]}
            """
        guard let dict = deserializeJSONObject(wireProtocol) else {
            XCTFail("ERROR decoding JSON")
            return
        }
        
        let expectedObj = OSRFObject(["can_haz_bacon": "t",
                                      "id": 1,
                                      "name": "Hormel"])
        do {
            let decodedObj = try OSRFCoder.decode(fromDictionary: dict)
            debugPrint(decodedObj)
            XCTAssertEqual(decodedObj, expectedObj)
        } catch {
            debugPrint(error)
            XCTFail(String(describing: error))
        }
    }

    // Case: decoding an array of OSRF objects from wire protocol
    func test_decode_wireArray() {
        OSRFCoder.registerClass("mbts", fields: ["balance_owed","id","last_billing_ts"])
        OSRFCoder.registerClass("circ", fields: ["checkin_lib","checkin_staff","checkin_time"])
        OSRFCoder.registerClass("mvr", fields: ["title","author","doc_id"])

        let wireProtocol = """
            [
                {
                    "transaction":{"__c":"mbts","__p":["1.15",182746988,"2018-01-10T23:59:59-0500"]},
                    "circ":{"__c":"circ","__p":[66,1175852,"2018-01-10T16:32:17-0500"]},
                    "record":{"__c":"mvr","__p":["Georgia adult literacy resources manual","State Bar of Georgia",1475710]},
                    "copy":null
                },
                {
                    "transaction":{"__c":"mbts","__p":["0.10",174615422,"2017-05-01T14:03:24-0400"]}
                }
            ]
            """
        guard let array = deserializeJSONObjectArray(wireProtocol) else {
            XCTFail("ERROR decoding JSON")
            return
        }

        do {
            let decodedArray = try OSRFCoder.decode(fromArray: array)
            XCTAssertEqual(decodedArray.count, 2)

            let obj = decodedArray[0]
            debugPrint(obj)
            let record = obj.getObject("record")
            XCTAssertNotNil(record)
            let title = record?.getString("title")
            XCTAssertEqual(title, "Georgia adult literacy resources manual")
            XCTAssertEqual(record?.getInt("doc_id"), 1475710)

            let obj1 = decodedArray[1]
            let record1 = obj1.getObject("record")
            XCTAssertNil(record1)
        } catch {
            debugPrint(error)
            XCTFail(String(describing: error))
        }
    }
}
