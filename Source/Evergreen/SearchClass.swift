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

class SearchClass {
    static let keyword = "keyword"
    static let title = "title"
    static let author = "author"
    static let subject = "subject"
    static let series = "series"
    static let identifier = "identifier"

    static func getSpinnerLabels() -> [String] {
        return ["Keyword","Title","Author","Subject","Series","ISBN or UPC"]
    }

    static func getSpinnerValues() -> [String] {
        return [keyword,title,author,subject,series,identifier]
    }
}
