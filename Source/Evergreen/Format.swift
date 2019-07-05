//
//  Format.swift
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

import Foundation

/// `Format` converts between:
/// - searchFormat as used by the OSRF search API,
/// - spinnerLabel as used in the UIPicker
/// - displayLabel as used in UI labels
class Format {
    struct FormatItem {
        var searchFormat: String
        var spinnerLabel: String
        var displayLabel: String?
        var hidden: Bool
    }

    static let items: [FormatItem] = {
        var items: [FormatItem] = []
        if
            let data = App.config.searchFormatsJSON.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonArray  = json as? [[String: Any?]]
        {
            for d in jsonArray {
                debugPrint(d)
                if
                    let searchFormat = d["f"] as? String,
                    let spinnerLabel = d["l"] as? String
                {
                    let displayLabel = d["L"] as? String ?? nil
                    let hidden = d["h"] as? Bool ?? false
                    let item = FormatItem(searchFormat: searchFormat, spinnerLabel: spinnerLabel, displayLabel: displayLabel, hidden: hidden)
                    debugPrint(item)
                    items.append(item)
                }
            }
        }
        return items
    }()
    
    //MARK: - Functions
    
    static func getSpinnerLabels() -> [String] {
        let shownItems = items.filter { !$0.hidden }
        return shownItems.map { $0.spinnerLabel }
    }
    
    static func getSearchFormat(forSpinnerLabel label: String) -> String {
        if let item = items.first(where: { $0.spinnerLabel == label }) {
            return item.searchFormat
        }
        return ""
    }
    
    static func getDisplayLabel(forSearchFormat searchFormat: String?) -> String {
        if (searchFormat ?? "").isEmpty {
            //print("kcxxx getDisplayLabel(\(searchFormat) -> \"\"")
            return ""
        }
        if let item = items.first(where: { $0.searchFormat == searchFormat }) {
            //print("kcxxx getDisplayLabel(\(searchFormat)) -> \"\(item.displayLabel ?? item.spinnerLabel)\"")
            return item.displayLabel ?? item.spinnerLabel
        }
        //print("kcxxx getDisplayLabel(\(searchFormat) -> \"\"")
        return ""
    }
    
    /*
    static func synchronized(_ lock: Any, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    static func initFromJSON() {
        synchronized(self) {
            
        }
    }
    */
}
