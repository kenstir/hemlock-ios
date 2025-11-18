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

protocol XSearchService {
    func makeQueryString(searchParameters: SearchParameters) -> String

    func fetchSearchResults(queryString: String, limit: Int) async throws -> XSearchResults

    func fetchCopyLocationCounts(recordID: Int, orgID: Int, orgLevel: Int) async throws -> [CopyLocationCounts]
}

struct SearchParameters {
    let text: String
    let searchClass: String
    let searchFormat: String?
    let searchOrg: String?
    let sort: String?
}

class XSearchResults {
    /// total number of matches in the catalog, may be higher than the number of [records] if results were limited
    let totalMatches: Int

    /// matching records
    ///
    /// these records are skeletons, and do not have Details, Attributes, or CopyCounts loaded
    let records: [AsyncRecord]

    init(totalMatches: Int, records: [AsyncRecord]) {
        self.totalMatches = totalMatches
        self.records = records
    }
}
