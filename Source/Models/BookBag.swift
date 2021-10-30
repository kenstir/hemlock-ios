/*
 * BookBag.swift
 *
 * Copyright (C) 2021 Kenneth H. Cox
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

class BookBag {
    var id: Int
    var name: String
    var obj: OSRFObject
    var items: [BookBagItem] = []
    var filterToVisibleRecords = false
    var visibleRecordIds: [Int] = []

    var description: String? {
        return obj.getString("description")
    }

    init(id: Int, name: String, obj: OSRFObject) {
        self.id = id
        self.name = name
        self.obj = obj
    }
    
    func initVisibleIds(fromQueryObj obj: OSRFObject) {
        filterToVisibleRecords = true
        visibleRecordIds = MBRecord.getIdsList(fromQueryObj: obj)
    }
    
    func loadItems(fromFleshedObj obj: OSRFObject) {
        items.removeAll()
        if let fleshedItems = obj.getAny("items") as? [OSRFObject] {
            for item in fleshedItems {
                if !filterToVisibleRecords {
                    items.append(BookBagItem(cbrebiObj: item))
                } else {
                    if let targetId = item.getInt("target_biblio_record_entry"),
                       visibleRecordIds.contains(targetId) {
                        items.append(BookBagItem(cbrebiObj: item))
                    }
                }
            }
        }
    }

    static func makeArray(_ objects: [OSRFObject]) -> [BookBag] {
        var ret: [BookBag] = []
        for obj in objects {
            if let id = obj.getInt("id"),
               let name = obj.getString("name")
            {
                ret.append(BookBag(id: id, name: name, obj: obj))
            }
        }
        return ret
    }
}
