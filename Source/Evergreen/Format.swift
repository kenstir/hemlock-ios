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
            let data = formatItemsJSON.data(using: .utf8),
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
    static let formatItemsJSON = """
[
  {"l":"All Formats", "f":""},
  {"l":"All Books", "f":"book", "L":"Book"},
  {"l":"All Music", "f":"music", "L":"Music"},
  {"l":"Audiocassette music recording", "f":"casmusic", "h":true},
  {"l":"Blu-ray", "f":"blu-ray"},
  {"l":"Braille", "f":"braille", "h":true},
  {"l":"Cassette audiobook", "f":"casaudiobook", "h":true},
  {"l":"CD Audiobook", "f":"cdaudiobook"},
  {"l":"CD Music recording", "f":"cdmusic"},
  {"l":"DVD", "f":"dvd"},
  {"l":"E-audio", "f":"eaudio"},
  {"l":"E-book", "f":"ebook"},
  {"l":"E-video", "f":"evideo"},
  {"l":"Equipment, games, toys", "f":"equip", "h":true},
  {"l":"Kit", "f":"kit", "h":true},
  {"l":"Large Print Book", "f":"lpbook"},
  {"l":"Map", "f":"map", "h":true},
  {"l":"Microform", "f":"microform", "h":true},
  {"l":"Music Score", "f":"score", "h":true},
  {"l":"Phonograph music recording", "f":"phonomusic", "h":true},
  {"l":"Phonograph spoken recording", "f":"phonospoken", "h":true},
  {"l":"Picture", "f":"picture"},
  {"l":"Serials and magazines", "f":"serial"},
  {"l":"Software and video games", "f":"software"},
  {"l":"VHS", "f":"vhs", "h":true}
]
"""
    
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
    
    // The API call open-ils.pcrud.retrieve.mra returns an abomination
    // of perl Data::Dumper hash output that we need to decode to get the
    // search format.  The string contains at least icon_format and
    // search_format entries, e.g.
    //
    //     "icon_format"=>"lpbook", "search_format"=>"book"
    //
    // We use "icon_format" because it is more specific, here it is
    // "lpbook" (Large Print Book) vs. "book" (Book).
    static func getSearchFormat(fromMRAObject obj: OSRFObject) -> String {
        if let attrs = obj.getString("attrs") {
            return getSearchFormat(fromMRAResponse: attrs)
        }
        return ""
    }
    static func getSearchFormat(fromMRAResponse mra: String) -> String {
        for entry in mra.split(onString: ", ") {
            let kv = entry.split(onString: "=>")
            if kv.count == 2, kv[0] == "\"icon_format\"" {
                return kv[1].trimQuotes()
            }
        }
        return ""
    }
    
    static func getDisplayLabel(forSearchFormat searchFormat: String?) -> String {
        if (searchFormat ?? "").isEmpty {
            return ""
        }
        if let item = items.first(where: { $0.searchFormat == searchFormat }) {
            return item.displayLabel ?? item.spinnerLabel
        }
        return ""
    }
    
    static func isOnlineResource(forSearchFormat searchFormat: String) -> Bool {
        if searchFormat == "picture" {
            return true
        }
        let label = Format.getDisplayLabel(forSearchFormat: searchFormat)
        return label.hasPrefix("E-")
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
