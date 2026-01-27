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

class BookBag: PatronList, Identifiable {
    let id: Int
    var name: String
    var obj: OSRFObject
    var items: [ListItem] = []
    var filterToVisibleRecords = false
    var visibleRecordIds: [Int] = []

    var description: String? {
        return obj.getString("description")
    }
    var isPublic: Bool {
        return obj.getBool("pub") ?? false
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

    func distinctBy(_ array: [OSRFObject], selector: (OSRFObject) -> Int?) -> [OSRFObject] {
        var set: Set<Int> = []
        var ret: [OSRFObject] = []
        for item in array {
            if let itemIndex = selector(item) {
                if set.insert(itemIndex).inserted {
                    ret.append(item)
                }
            }
        }
        return ret
    }

    func loadItems(fromFleshedObj obj: OSRFObject) {
        items.removeAll()
        if let fleshedItems = obj.getAny("items") as? [OSRFObject]
        {
            let distinctItems = distinctBy(fleshedItems) { $0.getInt("target_biblio_record_entry") }
            for item in distinctItems {
                if !filterToVisibleRecords {
                    items.append(BookBagItem(cbrebiObj: item))
                } else {
                    if let targetId = item.getInt("target_biblio_record_entry"),
                        visibleRecordIds.contains(targetId)
                    {
                        items.append(BookBagItem(cbrebiObj: item))
                    }
                }
            }
        }
        Analytics.logEvent(event: Analytics.Event.bookbagLoad, parameters: [Analytics.Param.numItems: items.count])
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

#if DEBUG
let testData = [
    BookBag(id: 1, name: "books to read", obj: OSRFObject([
        "description": "books I have not read"
    ])),
    BookBag(id: 2, name: "movies to watch with A", obj: OSRFObject([
        "description": nil
    ])),
    BookBag(id: 3, name: "movies to watch", obj: OSRFObject([
        "description": "movies nobody else but me would like"
    ])),
]
#endif
