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

import Foundation

struct CodedValue {
    let code: String
    let value: String
    let opacVisible: Bool
}

class CodedValueMap {
    
    static let allFormats = "All Formats"

    static var iconFormats: [CodedValue] = []
    static var searchFormats: [CodedValue] = []

    static func load(fromArray objects: [OSRFObject]) -> Void {
        iconFormats = []
        searchFormats = []
        for obj in objects {
            if let ctype = obj.getString("ctype"),
                let code = obj.getString("code"),
                let opacVisible = obj.getBool("opac_visible") {
                let searchLabel = obj.getString("search_label")
                let value = obj.getString("value")
                let codedValue = CodedValue(code: code, value: searchLabel ?? value ?? "", opacVisible: opacVisible)
                if ctype == "search_format" {
                    searchFormats.append(codedValue)
                } else if ctype == "icon_format" {
                    iconFormats.append(codedValue)
                }
            }
        }
    }
    
    static func iconFormatLabel(forCode code: String?) -> String {
        if let cv = iconFormats.first(where: { $0.code == code }) {
            return cv.value
        }
        return ""
    }

    static func searchFormatLabel(forCode code: String) -> String {
        if let cv = searchFormats.first(where: { $0.code == code }) {
            return cv.value
        }
        return ""
    }
    
    static func searchFormatCode(forLabel label: String) -> String {
        if let cv = searchFormats.first(where: { $0.value == label }) {
            return cv.code
        }
        return ""
    }
    
    static func searchFormatSpinnerLabels()  -> [String] {
        var labels: [String] = []
        for cv in searchFormats {
            if cv.opacVisible {
                labels.append(cv.value)
            }
        }
        labels = labels.sorted()
        labels.insert(allFormats, at: 0)
        return labels
    }
}
