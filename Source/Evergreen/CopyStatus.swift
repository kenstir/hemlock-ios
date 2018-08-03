//
//  CopyStatus.swift
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

class CopyStatus {
    
    static var status: [Int: String] = [:]
    
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    static func getLabel(forID id: Int) -> String {
        if let name = status[id] {
            return name
        }
        return ""
    }
    
    static func loadCopyStatus(fromArray objects: [OSRFObject]) -> Void {
        status = [:]
        for obj in objects {
            if let id = obj.getInt("id"),
                let name = obj.getString("name"),
                let opac_visible = obj.getBool("opac_visible"),
                opac_visible
            {
                CopyStatus.status[id] = name
                print("xxxcopy \(id) \(name) \(opac_visible)")
            }
        }
    }
    
    static func find(byID id: Int) -> String? {
        if let statusLabel = status[id] {
            return statusLabel
        }
        return nil
    }
}
