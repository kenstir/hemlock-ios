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
    func makeQueryString(searchText: String, searchClass: String?, searchFormat: String?, sort: String?) -> String

    func searchCatalog(queryString: String, limit: Int) async throws -> XSearchResults

    func fetchCopyLocationCounts(recordId: Int, orgId: Int, orgLevel: Int) async throws -> [CopyLocationCounts]
}

protocol XSearchResults {
    /// number of results returned
    var numResults: Int { get }

    /// total number of matches in the catalog, may be higher than [numResults] if results were limited
    var totalMatches: Int { get }

    /// matching records
    ///
    /// these records are skeletons, and do not have Details, Attributes, or CopyCounts loaded
    var records: [MBRecord] { get }
}
