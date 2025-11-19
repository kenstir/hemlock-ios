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

protocol BibRecord: AnyObject {
    var id: Int { get set }

    var author: String { get }
    var iconFormatLabel: String { get }
    var isbn: String { get }
    var physicalDescription: String { get }
    var pubdate: String { get }
    var pubinfo: String { get }
    var subject: String { get }
    var synopsis: String { get }
    var title: String { get }
    var titleSortKey: String { get }

    var hasAttributes: Bool { get }
    var hasMetadata: Bool { get }
    var hasMARC: Bool { get }
    var isDeleted: Bool { get }
    var isPreCat: Bool { get }

    var attrs: [String: String]? { get }
    var marcRecord: MARCRecord? { get }
    var copyCounts: [CopyCount]? { get }

    func totalCopies(atOrgID orgID: Int?) -> Int
}
