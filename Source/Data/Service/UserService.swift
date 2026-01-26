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

protocol UserService {
    //MARK: - Session Management
    func loadSession(account: Account) async throws -> Void
    func deleteSession(account: Account) async throws -> Void

    //MARK: - Patron Lists
    func loadPatronLists(account: Account) async throws -> Void
    func loadPatronListItems(account: Account, patronList: PatronList) async throws -> Void
    func createPatronList(account: Account, name: String, description: String) async throws -> Void
    func deletePatronList(account: Account, listId: Int) async throws -> Void
    func addItemToPatronList(account: Account, listId: Int, recordId: Int) async throws -> Void
    func removeItemFromPatronList(account: Account, listId: Int, itemId: Int) async throws -> Void

    //MARK: - User Settings
    func updatePushNotificationToken(account: Account, token: String?) async throws -> Void
    func enableCheckoutHistory(account: Account) async throws -> Void
    func disableCheckoutHistory(account: Account) async throws -> Void
    func clearCheckoutHistory(account: Account) async throws -> Void
    func changePickupOrg(account: Account, orgId: Int) async throws -> Void

    //MARK: - Messages
    func fetchPatronMessages(account: Account) async throws -> [PatronMessage]
    func markMessageRead(account: Account, messageID: Int) async throws -> Void
    func markMessageUnread(account: Account, messageID: Int) async throws -> Void
    func markMessageDeleted(account: Account, messageID: Int) async throws -> Void

    //MARK: - Charges (Fines)
    func fetchPatronCharges(account: Account) async throws -> PatronCharges
    func payChargesUrl(account: Account) -> String
    func isPayChargesEnabled(account: Account) -> Bool
}
