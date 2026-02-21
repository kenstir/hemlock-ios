//
//  AnalyticsTests.swift
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

class AnalyticsTests: XCTestCase {

    override class func setUp() {
        TestUtils.loadExampleOrgs()
    }

    func test_getLog() {
        Analytics.clearLog()
        Analytics.logRequest(tag: "dedbeef", method: "m", args: ["p1","p2"])
        Analytics.logResponse(tag: "dedbeef", wireString: "{}")
        let s = Analytics.getLog()
        XCTAssertEqual("[net] dedbeef  send  m p1,p2\n[net] dedbeef  recv  {}\n", s)
    }

    func test_searchTermStats() {
        do {
            let stats = Analytics.searchTermParameters(searchTerm: "La la land")
            XCTAssertEqual(stats[Analytics.Param.searchTermNumUniqueWords], 2)
            XCTAssertEqual(stats[Analytics.Param.searchTermAverageWordLengthX10], 30)
        }
        do {
            let stats = Analytics.searchTermParameters(searchTerm: "Potter Goblet")
            XCTAssertEqual(stats[Analytics.Param.searchTermNumUniqueWords], 2)
            XCTAssertEqual(stats[Analytics.Param.searchTermAverageWordLengthX10], 60)
        }
        do {
            let stats = Analytics.searchTermParameters(searchTerm: "!")
            XCTAssertEqual(stats[Analytics.Param.searchTermNumUniqueWords], 0)
            XCTAssertEqual(stats[Analytics.Param.searchTermAverageWordLengthX10], 0)
        }
    }

    func test_orgDimension() {
        let consortiumService = App.svc.consortium
        let CONS = consortiumService.find(byShortName: "CONS")
        let BR1 = consortiumService.find(byShortName: "BR1")
        let BR2 = consortiumService.find(byShortName: "BR2")

        XCTAssertEqual("null",
                       Analytics.orgDimension(selectedOrg: BR1, defaultOrg: nil, homeOrg: nil))
        XCTAssertEqual("default",
                       Analytics.orgDimension(selectedOrg: BR1, defaultOrg: BR1, homeOrg: BR1))
        XCTAssertEqual("other",
                       Analytics.orgDimension(selectedOrg: BR2, defaultOrg: BR1, homeOrg: BR1))
        XCTAssertEqual("CONS",
                       Analytics.orgDimension(selectedOrg: CONS, defaultOrg: BR2, homeOrg: BR1))
        XCTAssertEqual("home",
                       Analytics.orgDimension(selectedOrg: BR1, defaultOrg: BR2, homeOrg: BR1))
    }

    func test_boolValue() {
        XCTAssertEqual("true", Analytics.boolValue(true))
        XCTAssertEqual("false", Analytics.boolValue(false))
    }
}
