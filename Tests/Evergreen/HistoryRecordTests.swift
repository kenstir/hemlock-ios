/*
 * Copyright (C) 2020 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import XCTest
@testable import Hemlock

class HistoryRecordTests: XCTestCase {

    let unreturnedObj = OSRFObject([
        "target_copy": 4801942,
        "xact_start": "2023-12-27T17:55:01-0500",
        "due_date": "2024-01-03T23:59:59-0500",
        "source_circ": 124207113,
        "id": 9297488,
        "checkin_time": nil
    ], netClass: "auch")
    let returnedObj = OSRFObject([
        "target_copy": 18092886,
        "xact_start": "2023-07-05T18:20:39-0400",
        "due_date": "2023-07-26T23:59:59-0400",
        "source_circ": 119438804,
        "id": 8912637,
        "checkin_time": "2023-07-20T12:19:54-0400"
    ], netClass: "auch")

    func test_makeArray() {
        let objs = HistoryRecord.makeArray([unreturnedObj, returnedObj])
        XCTAssertEqual(2, objs.count)
        XCTAssertEqual(9297488, objs.first?.id)
        XCTAssertEqual("Unknown Title", objs.first?.title)
    }
}
