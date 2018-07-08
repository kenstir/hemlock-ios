//
//  ResultRecord.swift
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
//

import Foundation

class ResultRecord {
    
    let id: Int
    var mvrObj: OSRFObject?
    
    var title: String { return mvrObj?.getString("title") ?? "Unknown" }
    var author: String { return mvrObj?.getString("author") ?? "Unknown" }
    
    init(id: Int) {
        self.id = id
    }
    
    // Create array of skeleton ResultRecords from the multiclassQuery response object.
    // The object has an "ids" field that is a list of lists and looks like one of:
    //   [[32673,null,"0.0"],[886843,null,"0.0"]]      // integer id,?,?
    //   [["503610",null,"0.0"],["502717",null,"0.0"]] // string id,?,?
    //   [["1805532"],["2385399"]]                     // string id only
    static func makeArray(fromQueryResponse obj: OSRFObject) -> [ResultRecord] {
        var records: [ResultRecord] = []

        // early exit if there are no results
        let count = obj.getInt("count")
        if count == 0 {
            return records
        }
        
        // construct the list
        if let ids = obj.getAny("ids"),
            let ids_array = ids as? [[Any]]
        {
            for elem in ids_array {
                if let id = elem.first as? Int {
                    records.append(ResultRecord(id: id))
                } else if let str = elem.first as? String, let id = Int(str) {
                    records.append(ResultRecord(id: id))
                } else {
                    Analytics.logError(code: .shouldNotHappen, msg: "Unexpected id in results: \(String(describing: elem.first))", file: #file, line: #line)
                }
            }
        } else {
            Analytics.logError(code: .shouldNotHappen, msg: "Unexpected ids format in results: \(String(describing: obj.getAny("ids")))", file: #file, line: #line)
        }
        return records
    }
}