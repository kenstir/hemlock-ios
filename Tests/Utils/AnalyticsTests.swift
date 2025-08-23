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

    func test_getLog() {
        Analytics.clearLog()
        Analytics.logRequest(tag: "dedbeef", method: "m", args: ["p1","p2"])
        Analytics.logResponse(tag: "dedbeef", wireString: "{}")
        let s = Analytics.getLog()
        XCTAssertEqual("[net] dedbeef  send  m p1,p2\n[net] dedbeef  recv  {}\n", s)
    }

    func test_searchTermStats() {
        let stats = Analytics.searchTermParameters(searchTerm: "La la land")
        XCTAssertEqual(stats[Analytics.Param.searchTermNumUniqueWords], 2)
        XCTAssertEqual(stats[Analytics.Param.searchTermAverageWordLengthX10], 30)

        let stats2 = Analytics.searchTermParameters(searchTerm: "Potter Goblet")
        XCTAssertEqual(stats2[Analytics.Param.searchTermNumUniqueWords], 2)
        XCTAssertEqual(stats2[Analytics.Param.searchTermAverageWordLengthX10], 60)
    }
}
