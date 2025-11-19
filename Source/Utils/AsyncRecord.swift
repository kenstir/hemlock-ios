//  Copyright (C) 2023 Kenneth H. Cox
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

import os.log

/// AsyncRecord adds asynchronous loading to MBRecord for prefetching.
class AsyncRecord: BibRecord {

    //MARK: - Properties

    let row: Int

    //MARK: - Lifecycle

    init(id: Int, row: Int) {
        self.row = row

        super.init(id: id)
    }

    //MARK: - Functions

    func isLoaded() -> Bool {
        return hasMetadata && hasAttributes
    }

    /// `prefetch` does asynchronous prefetching of details and attributes.
    ///  It does not throw because we use it for preloading table rows.
    func prefetch() async -> Void {
        print("\(Utils.tt) row=\(String(format: "%2d", row)) prefetch hasMetadata=\(self.hasMetadata) hasAttrs=\(self.hasAttributes)")

        async let details: Void = App.serviceConfig.biblioService.loadRecordDetails(forRecord: self, needMARC: false)
        async let attrs: Void = App.serviceConfig.biblioService.loadRecordAttributes(forRecord: self)
        let _ = try? await (details, attrs)
    }

    //MARK: - Static Functions

    static func makeArray(fromQueryResponse theobj: OSRFObject?) -> [AsyncRecord] {
        let recordIds = BibRecord.getIdsList(fromQueryObj: theobj)
        var ret: [AsyncRecord] = []
        for (row, id) in recordIds.enumerated() {
            ret.append(AsyncRecord(id: id, row: row))
        }
        return ret
    }
}
