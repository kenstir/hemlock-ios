//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import Foundation

class EvergreenBiblioService: XBiblioService {
    func imageUrl(forRecord record: MBRecord) -> String? {
        return nil
    }

    func loadRecordDetails(forRecord record: MBRecord, needMARC: Bool) async throws -> Void {
        // load MODS and MARC data for the record, but only if it wasn't already done
        try await withThrowingTaskGroup(of: Void.self) { group in
            if !record.hasMODS {
                group.addTask {
                    let modsObj = try await EvergreenAsync.fetchRecordMODS(id: record.id)
                    record.setMvrObj(modsObj)
                }
            }
            if !record.hasMARC {
                group.addTask {
                    let breObj = try await EvergreenAsync.fetchBRE(id: record.id)
                    record.update(fromBreObj: breObj)
                }
            }
            try await group.waitForAll()
        }
    }

    func loadRecordAttributes(forRecord record: MBRecord) async throws {
        if !record.hasAttrs {
            let mraObj = try await EvergreenAsync.fetchMRA(id: record.id)
            record.update(fromMraObj: mraObj)
        }
    }

    func loadRecordCopyCounts(forRecord record: MBRecord, orgId: Int) async throws {
        let array = try await SearchService.fetchCopyCount(recordID: record.id, orgID: orgId)
        let copyCounts = CopyCount.makeArray(fromArray: array)
        record.setCopyCounts(copyCounts)
    }
}
