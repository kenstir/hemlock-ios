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
    func makeQueryString(searchText: String, searchClass: String, searchFormat: String?, sort: String?) -> String {
        var query = "\(searchClass):\(searchText)"
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
    
    func searchCatalog(queryString: String, limit: Int) async throws -> any XSearchResults {
        <#code#>
    }
    
    func fetchCopyLocationCounts(recordId: Int, orgId: Int, orgLevel: Int) async throws -> [CopyLocationCounts] {
        <#code#>
    }
}
