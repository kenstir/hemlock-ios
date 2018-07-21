//
//  SMSCarrier.swift
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

class SMSCarrier {
    
    static var carriers: [SMSCarrier] = []

    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    static func loadSMSCarriers(fromArray objects: [OSRFObject]) throws -> Void {
        carriers = []
        for obj in objects {
            if let id = obj.getInt("id"),
                let name = obj.getString("name") {
                carriers.append(SMSCarrier(id: id, name: name))
            }
        }
    }
    
    static func find(byName name: String) -> SMSCarrier? {
        if let carrier = carriers.first(where: { $0.name == name }) {
            return carrier
        }
        return nil
    }

    static func getSpinnerLabels() -> [String] {
        return carriers.map { $0.name }
    }
}
