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

class EvergreenSearchService: XSearchService {
    func makeQueryString(searchParameters sp: SearchParameters) -> String {
        // Taken with a grain of salt from
        // https://wiki.evergreen-ils.org/doku.php?id=documentation:technical:search_grammar
        // e.g. "title:Harry Potter chamber of secrets search_format(book) site(MARLBORO)"
        var query = "\(sp.searchClass):\(sp.text)"
        if let sf = sp.searchFormat, !sf.isEmpty {
            query += " search_format(\(sf))"
        }
        if let org = sp.organizationShortName, !org.isEmpty {
            query += " site(\(org))"
        }
        if let sort = sp.sort {
            query += " sort(\(sort))"
        }
        return query
    }

    func fetchSearchResults(queryString: String, limit: Int) async throws -> XSearchResults {
        let options: [String: Int] = ["limit": App.config.searchLimit, "offset": 0]
//            if query.contains("throw") { throw HemlockError.shouldNotHappen("Testing error handling") }
        let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, queryString, 1], shouldCache: true)
        let obj = try await req.gatewayResponseAsync().asObjectOrNil()

        let count = obj?.getInt("count") ?? 0
        let records: [AsyncRecord] = AsyncRecord.makeArray(fromQueryResponse: obj)
        return XSearchResults(totalMatches: count, records: records)
    }

    func fetchCopyLocationCounts(recordId: Int, orgId: Int, orgLevel: Int) async throws -> [CopyLocationCounts] {
        return []
    }
}
