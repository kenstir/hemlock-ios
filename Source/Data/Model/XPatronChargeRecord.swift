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

protocol XPatronChargeRecord {
    var title: String { get }
    var subtitle: String { get }
    var balanceOwed: Double? { get }
    var status: String { get }
    var record: BibRecord? { get }
}

class PatronCharges {
    let totalCharges: Double
    let totalPaid: Double
    let balanceOwed: Double
    let transactions: [XPatronChargeRecord]

    init(totalCharges: Double, totalPaid: Double, balanceOwed: Double, transactions: [XPatronChargeRecord]) {
        self.totalCharges = totalCharges
        self.totalPaid = totalPaid
        self.balanceOwed = balanceOwed
        self.transactions = transactions
    }
}
