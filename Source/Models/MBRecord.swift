/*
 * Copyright (C) 2018 Kenneth H. Cox
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

import Foundation

/// Metabib Record
class MBRecord {
    
    var id: Int
    var mvrObj: OSRFObject?
    var attrs: [String: String]? // from MRA object
    var marcRecord: MARCRecord?
    var copyCounts: [CopyCount]?

    var title: String { return mvrObj?.getString("title") ?? "" }
    var author: String { return mvrObj?.getString("author") ?? "" }
    var iconFormatLabel: String { return CodedValueMap.iconFormatLabel(forCode: attrs?["icon_format"]) }
    var edition: String? { return mvrObj?.getString("edition") }
    var isbn: String { return mvrObj?.getString("isbn") ?? "" }
    var firstOnlineLocationInMVR: String? {
        if let arr = mvrObj?.getAny("online_loc") as? [String] {
            return arr.first
        }
        return nil
    }
    var pubdate: String { return mvrObj?.getString("pubdate") ?? "" }
    var pubinfo: String {
        let pubdate = mvrObj?.getString("pubdate") ?? ""
        let publisher = mvrObj?.getString("publisher") ?? ""
        return (pubdate + " " + publisher).trim()
    }
    var synopsis: String { return mvrObj?.getString("synopsis") ?? "" }
    var subject: String {
        if let obj = mvrObj?.getObject("subject") {
            return obj.dict.keys.joined(separator: "\n")
        }
        return ""
    }
//    var searchFormat: String? {
//        return attrs?["search_format"]
//    }

    init(id: Int, mvrObj: OSRFObject? = nil) {
        self.id = id
        self.mvrObj = mvrObj        
    }
    
    //MARK: - Functions
    
    // Create array of skeleton records from the multiclassQuery response object.
    // The object has an "ids" field that is a list of lists and looks like one of:
    //   [[32673,null,"0.0"],[886843,null,"0.0"]]      // integer id,?,?
    //   [["503610",null,"0.0"],["502717",null,"0.0"]] // string id,?,?
    //   [["1805532"],["2385399"]]                     // string id only
    static func makeArray(fromQueryResponse theobj: OSRFObject?) -> [MBRecord] {
        var records: [MBRecord] = []
        
        // early exit if there are no results
        guard let obj = theobj,
            let count = obj.getInt("count"),
            count > 0 else {
            return records
        }
        
        // construct the list
        if let ids = obj.getAny("ids") as? [[Any]]
        {
            for elem in ids {
                if let id = elem.first as? Int {
                    records.append(MBRecord(id: id))
                } else if let str = elem.first as? String, let id = Int(str) {
                    records.append(MBRecord(id: id))
                } else {
                    Analytics.logError(code: .shouldNotHappen, msg: "Unexpected element in ids list: \(elem))", file: #file, line: #line)
                }
            }
        } else {
            Analytics.logError(code: .shouldNotHappen, msg: "Unexpected format of ids list: \(String(describing: obj.getAny("ids")))", file: #file, line: #line)
        }
        return records
    }

    static func getIdsList(fromQueryObj obj: OSRFObject) -> [Int] {
        var ret: [Int] = []

        if let ids = obj.getAny("ids") as? [[Any]] {
            for elem in ids {
                if let id = elem.first as? Int {
                    ret.append(id)
                } else if let str = elem.first as? String, let id = Int(str) {
                    ret.append(id)
                } else {
                    Analytics.logError(code: .shouldNotHappen, msg: "Unexpected element in ids list: \(elem))", file: #file, line: #line)
                }
            }
        } else {
            Analytics.logError(code: .shouldNotHappen, msg: "Unexpected format of ids list: \(String(describing: obj.getAny("ids")))", file: #file, line: #line)
        }
        return ret
    }
}
