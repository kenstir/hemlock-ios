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

/// A `CircRecord` is a record of an item in circulation
protocol CircRecord {
    var id: Int { get }
    var targetCopy: Int { get }
    var title: String { get }
    var author: String { get }
    var dueDate: Date? { get }
    var dueDateLabel: String { get }
    var renewalsRemaining: Int { get }
    var autoRenewals: Int { get }
    var wasAutoRenewed: Bool { get }
    var isOverdue: Bool { get }
    var isDueSoon: Bool { get }
    var metabibRecord: BibRecord? { get }
}

