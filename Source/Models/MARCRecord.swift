//
//  MARCXMLRecord.swift
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

struct MARCSubfield {
    let code: String
    var text: String?
    init(code: String) {
        self.code = code
    }
}

struct MARCDatafield {
    let tag: String
    let ind1: String
    let ind2: String
    var subfields: [MARCSubfield] = []
    init(tag: String, ind1: String, ind2: String) {
        self.tag = tag
        self.ind1 = ind1
        self.ind2 = ind2
    }
    
    var isOnlineLocation: Bool {
        return (tag == "856" && ind1 == "4" && (ind2 == "0" || ind2 == "1"))
    }

    var uri: String? {
        return subfields.first(where: { $0.code == "u" })?.text
    }

    var linkText: String? {
        return subfields.first(where: { $0.code == "3" || $0.code == "y" })?.text

    }
}

struct MARCRecord {
    var datafields: [MARCDatafield] = []
}
