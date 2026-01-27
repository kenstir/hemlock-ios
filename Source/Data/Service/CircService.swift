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

protocol CircService {
    /// Fetches the current checkouts
    ///
    /// Returns a list of skeleton records, that must be fleshed out with loadCheckoutDetails.
    func fetchCheckouts(account: Account) async throws -> [CircRecord]

    /// Loads the details for a specific circ record
    func loadCheckoutDetails(account: Account, circRecord: CircRecord) async throws -> Void

    /// Renews a checkout
    func renewCheckout(account: Account, targetCopy: Int) async throws -> Bool

    /// Fetches the checkout history
    func fetchCheckoutHistory(account: Account) async throws -> [HistoryRecord]

    /// Loads the details for a specific history record
    func loadHistoryDetails(historyRecord: HistoryRecord) async throws -> Void

    /// Fetches the holds
    func fetchHolds(account: Account) async throws -> [HoldRecord]

    /// Loads the details for a specific hold record
    func loadHoldDetails(account: Account, hold: HoldRecord) async throws -> Void

    /// Fetches the parts available to place a hold
    func fetchHoldParts(targetID: Int) async throws -> [HoldPart]

    /// Fetches whether a title hold is possible for the given item with parts for the specified pickup library
    func fetchTitleHoldIsPossible(account: Account, targetID: Int, pickupOrgID: Int) async throws -> Bool

    /// Places a hold
    func placeHold(account: Account, targetID: Int, withOptions options: HoldOptions) async throws -> Bool

    /// Updates an existing hold with new options.
    func updateHold(account: Account, holdID: Int, withOptions options: HoldUpdateOptions) async throws -> Bool

    /// Cancels a hold
    func cancelHold(account: Account, holdID: Int) async throws -> Bool
}
