//
//  RecordAttributes.swift
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

class RecordAttributes {

    // The API call open-ils.pcrud.retrieve.mra returns an abomination
    // of perl Data::Dumper hash output that we need to decode to get the
    // search format.  The string contains at least icon_format and
    // search_format entries, e.g.
    //
    //     "icon_format"=>"lpbook", "search_format"=>"book"
    //
    // For searchFormat we use "icon_format" because it is more specific
    // than search_format; here it is "lpbook" (Large Print Book) vs. "book" (Book).
    //
    static func parseAttributes(fromMRAObject obj: OSRFObject) -> [String: String] {
        guard let attrsDump = obj.getString("attrs") else { return [:] }
        return parseAttributes(fromMRAString: attrsDump)
    }

    static func parseAttributes(fromMRAString attrsDump: String) -> [String: String] {
        var attrs: [String: String] = [:]
        for entry in attrsDump.split(onString: ", ") {
            let kv = entry.split(onString: "=>")
            if kv.count == 2 {
                attrs[kv[0].trimQuotes()] = kv[1].trimQuotes()
            }
        }
        return attrs
    }
}
