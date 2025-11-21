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
    func imageUrl(forRecord record: BibRecord) -> String? {
        return nil
    }

    func loadRecordDetails(forRecord bibRecord: BibRecord, needMARC: Bool) async throws -> Void {
        guard let record = bibRecord as? MBRecord else { throw HemlockError.internalError("Expected MBRecord, got \(type(of: bibRecord))") }

        // load MODS and MARC data for the record, but only if it wasn't already done
        try await withThrowingTaskGroup(of: Void.self) { group in
            if !record.hasMetadata {
                group.addTask {
                    let modsObj = try await EvergreenAsync.fetchRecordMODS(id: record.id)
                    record.setMvrObj(modsObj)
                }
            }
            if needMARC && !record.hasMARC {
                group.addTask {
                    let breObj = try await EvergreenAsync.fetchBRE(id: record.id)
                    record.update(fromBreObj: breObj)
                }
            }
            try await group.waitForAll()
        }
    }

    func loadRecordAttributes(forRecord bibRecord: BibRecord) async throws {
        guard let record = bibRecord as? MBRecord else { throw HemlockError.internalError("Expected MBRecord, got \(type(of: bibRecord))") }

        if !record.hasAttributes {
            let mraObj = try await EvergreenAsync.fetchMRA(id: record.id)
            record.update(fromMraObj: mraObj)
        }
    }

    func loadRecordCopyCounts(forRecord bibRecord: BibRecord, orgId: Int) async throws {
        guard let record = bibRecord as? MBRecord else { throw HemlockError.internalError("Expected MBRecord, got \(type(of: bibRecord))") }

        let array = try await fetchCopyCount(recordID: record.id, orgID: orgId)
        let copyCounts = EvergreenCopyCount.makeArray(fromArray: array)
        record.setCopyCounts(copyCounts)
    }

    private func fetchCopyCount(recordID: Int, orgID: Int) async throws -> [OSRFObject] {
        let req = Gateway.makeRequest(service: API.search, method: API.copyCount, args: [orgID, recordID], shouldCache: false)
        return try await req.gatewayResponseAsync().asArray()
    }
}
