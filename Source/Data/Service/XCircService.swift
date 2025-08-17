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

protocol XCircService {
    /// Fetches the current checkouts
    ///
    /// Returns a list of skeleton records, that must be fleshed out with loadCheckoutDetails.
    func fetchCheckouts(account: Account) async throws -> [CircRecord]

    /// Loads the details for a specific circ record
    func loadCheckoutDetails(account: Account, circRecord: CircRecord) async throws -> Void

    /// Renews a checkout
    func renewCheckout(account: Account, targetCopy: Int) async throws -> Bool
}
