//
//  Copyright (C) 2019 Kenneth H. Cox
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

class CodedValueMapTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_basic() {
        var objects: [OSRFObject] = []
        objects.append(OSRFObject([
            "ctype": "search_format",
            "opac_visible": true,
            "code": "book",
            "value": "Book (All)"
            ]))
        objects.append(OSRFObject([
            "ctype": "icon_format",
            "opac_visible": true,
            "code": "book",
            "value": "Book"
            ]))
        CodedValueMap.load(fromArray: objects)
        
        XCTAssertEqual("", CodedValueMap.searchFormatLabel(forCode: ""))
        XCTAssertEqual("", CodedValueMap.iconFormatLabel(forCode: ""))
        let s: String? = nil
        XCTAssertEqual("", CodedValueMap.iconFormatLabel(forCode: s))

        XCTAssertEqual("Book (All)", CodedValueMap.searchFormatLabel(forCode: "book"))
        XCTAssertEqual("Book", CodedValueMap.iconFormatLabel(forCode: "book"))
        
        let labels = CodedValueMap.searchFormatSpinnerLabels()
        XCTAssertEqual(CodedValueMap.allFormats, labels.first)
    }
}
