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

import PromiseKit
import os.log

/// AsyncRecord adds asynchronous loading to MBRecord for prefetching.
class AsyncRecord: MBRecord {

    //MARK: - Properties

    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "AsyncRecord")
    private let row: Int
    private let lock = NSLock()
    var promises: [Promise<Void>] = []
    enum LoadState {
        case initial
        case started
        case loaded
    }
    private var state = LoadState.initial

    //MARK: - Lifecycle

    init(id: Int, row: Int) {
        self.row = row

        super.init(id: id)
    }

    //MARK: - Functions

    /// free-threaded
    func startPrefetchRecordDetails() -> [Promise<Void>] {
        os_log("[%s] row=%2d prefetch", log: AsyncRecord.log, type: .info, Thread.current.tag(), row)
        lock.lock()
        defer { lock.unlock() }

        switch state {
        case .initial:
            promises.append(SearchService.fetchRecordMODS(forRecord: self))
            promises.append(PCRUDService.fetchMRA(forRecord: self))
            state = .started
            return promises
        case .started:
            return promises
        case .loaded:
            return promises
        }
    }

    static func makeArray(fromQueryResponse theobj: OSRFObject?) -> [AsyncRecord] {
        let recordIds = MBRecord.getIdsList(fromQueryObj: theobj)
        var ret: [AsyncRecord] = []
        for (row, id) in recordIds.enumerated() {
            ret.append(AsyncRecord(id: id, row: row))
        }
        return ret
    }
}
