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
import Alamofire
import os.log

class EvergreenUserService: XUserService {
    //MARK: - Session Management

    func loadSession(account: Account) async throws {
        // authGetSession must be called first, before any other API calls taking an authtoken.
        let req = Gateway.makeRequest(service: API.auth, method: API.authGetSession, args: [account.authtoken], shouldCache: false)
        let obj = try await req.gatewayResponseAsync().asObject()
        print("\(Utils.tt) about to account.loadSession")
        account.loadSession(fromObject: obj)

        try await loadUserSettings(account: account)
    }

    private func loadUserSettings(account: Account) async throws {
        let fields = ["card", "settings"]
        let req = Gateway.makeRequest(service: API.actor, method: API.userFleshedRetrieve, args: [account.authtoken, account.userID, fields], shouldCache: false)
        let obj = try await req.gatewayResponseAsync().asObject()

        print("\(Utils.tt) about to account.loadUserSettings")
        account.loadUserSettings(fromObject: obj)
    }

    func deleteSession(account: Account) async throws {
        let req = Gateway.makeRequest(service: API.auth, method: API.authDeleteSession, args: [account.authtoken], shouldCache: false)
        let _ = try await req.gatewayResponseAsync().asString()

        print("\(Utils.tt) about to account.clear")
        account.clear()
    }

    //MARK: - Patron Lists (Book Bags)

    func loadPatronLists(account: Account) async throws {
        print("\(Utils.tt) loadPatronLists")
        let req = Gateway.makeRequest(service: API.actor, method: API.containerRetrieveByClass, args: [account.authtoken, account.userID, API.containerClassBiblio, API.containerTypeBookbag], shouldCache: false)
        let objects = try await req.gatewayResponseAsync().asArray()
        print("\(Utils.tt) about to call account.loadBookBags(fromArray:)")
        account.loadBookBags(fromArray: objects)
    }

    func loadPatronListItems(account: Account, patronList: XPatronList) async throws {
        print("\(Utils.tt) \(patronList.id) loadPatronListItems")
        let bookBag: BookBag = try requireType(patronList)

        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }
        let query = "container(bre,bookbag,\(patronList.id),\(authtoken))"
        let options = ["limit": 999]
        let queryReq = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 0], shouldCache: false)

        let allItemsReq = Gateway.makeRequest(service: API.actor, method: API.containerFlesh, args: [authtoken, API.containerClassBiblio, patronList.id], shouldCache: false)

        // await both
        // TODO: make parallel
        let queryObj = try await queryReq.gatewayResponseAsync().asObject()
        let allItemsObj = try await allItemsReq.gatewayResponseAsync().asObject()

        // TODO: make mt-safe, remove await
        await MainActor.run {
            print("\(Utils.tt) \(patronList.id) about to call .loadItems()")
            bookBag.initVisibleIds(fromQueryObj: queryObj)
            bookBag.loadItems(fromFleshedObj: allItemsObj)
        }
    }

    func createPatronList(account: Account, name: String, description: String) async throws {
        guard let authtoken = account.authtoken,
            let userID = account.userID else {
            throw HemlockError.sessionExpired
        }
        let obj = OSRFObject([
            "btype": API.containerTypeBookbag,
            "name": name,
            "description": description,
            "pub": false,
            "owner": userID,
        ], netClass: "cbreb")
        let req = Gateway.makeRequest(service: API.actor, method: API.containerCreate, args: [authtoken, API.containerClassBiblio, obj], shouldCache: false)
        let str = try await req.gatewayResponseAsync().asString()
        os_log("[lists] createBag %@ result %@", name, str)
    }

    func deletePatronList(account: Account, listId: Int) async throws {
        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.containerDelete, args: [authtoken, API.containerClassBiblio, listId], shouldCache: false)
        let str = try await req.gatewayResponseAsync().asString()
        os_log("[lists] bag %d deleteBag result %@", listId, str)
    }

    func addItemToPatronList(account: Account, listId: Int, recordId: Int) async throws {
        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }
        let obj = OSRFObject([
            "bucket": listId,
            "target_biblio_record_entry": recordId,
            "id": nil,
        ], netClass: "cbrebi")
        let req = Gateway.makeRequest(service: API.actor, method: API.containerItemCreate, args: [authtoken, API.containerClassBiblio, obj], shouldCache: false)
        let str = try await req.gatewayResponseAsync().asString()
        os_log("[lists] addItem %d result %@", listId, str)
    }

    func removeItemFromPatronList(account: Account, listId: Int, itemId: Int) async throws {
        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }
        let req = Gateway.makeRequest(service: API.actor, method: API.containerItemDelete, args: [authtoken, API.containerClassBiblio, itemId], shouldCache: false)
        let str = try await req.gatewayResponseAsync().asString()
        os_log("[lists] removeItem %d result %@", itemId, str)
    }

    //MARK: - User Settings

    func updatePushNotificationToken(account: Account, token: String?) async throws {
        guard let authtoken = account.authtoken, let userID = account.userID else { return }
        let settings: JSONDictionary = [
            API.userSettingHemlockPushNotificationData: token,
            API.userSettingHemlockPushNotificationEnabled: true
        ]
        let str = try await updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings)
        // `str` doesn't matter, it either worked or it errored.
        // TODO: do we have anything to do here?
        print("[fcm] token updated str=\(str)")
    }

    func enableCheckoutHistory(account: Account) async throws {
        guard let authtoken = account.authtoken, let userID = account.userID else { return }
        let dateString = OSRFObject.apiDayOnlyFormatter.string(from: Date())
        let settings: JSONDictionary = [API.userSettingCircHistoryStart: dateString]
        // return value doesn't matter, it either worked or it errored.
        let _ = try await updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings)
        account.setCircHistoryStart(dateString)
    }

    func disableCheckoutHistory(account: Account) async throws {
        guard let authtoken = account.authtoken, let userID = account.userID else { return }
        let dateString: String? = nil
        let settings: JSONDictionary = [API.userSettingCircHistoryStart: dateString]
        // return value doesn't matter, it either worked or it errored.
        let _ = try await updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings)
        account.setCircHistoryStart(dateString)
    }

    private func updatePatronSettings(authtoken: String, userID: Int, settings: JSONDictionary) async throws -> String {
        /// returns "1" or an error
        let req = Gateway.makeRequest(service: API.actor, method: API.patronSettingsUpdate, args: [authtoken, userID, settings], shouldCache: false)
        return try await req.gatewayResponseAsync().asString()
    }

    func clearCheckoutHistory(account: Account) async throws {
        guard let authtoken = account.authtoken else { return }
        let req = Gateway.makeRequest(service: API.actor, method: API.clearCheckoutHistory, args: [authtoken], shouldCache: false)
        // return value doesn't matter, it either worked or it errored.
        let _ = try await req.gatewayResponseAsync().asString()
    }

    func changePickupOrg(account: Account, orgId: Int) async throws {
        guard let authtoken = account.authtoken, let userID = account.userID else { return }
        let settings: JSONDictionary = [API.userSettingDefaultPickupLocation: orgId]
        // return value doesn't matter, it either worked or it errored.
        let _ = try await updatePatronSettings(authtoken: authtoken, userID: userID, settings: settings)
        account.pickupOrgID = orgId
    }

    //MARK: - Messages

    func fetchPatronMessages(account: Account) async throws -> [PatronMessage] {
        let req = Gateway.makeRequest(service: API.actor, method: API.messagesRetrieve, args: [account.authtoken, account.userID], shouldCache: false)
        let objects = try await req.gatewayResponseAsync().asArray()
        return EvergreenPatronMessage.makeArray(objects)
    }

    private func markMessageAction(account: Account, messageID: Int, action: String) async throws {
        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }
        var url = App.library?.url ?? ""
        url += "/eg/opac/myopac/messages?action=\(action)&message_id=\(messageID)"
        let req = Gateway.makeOPACRequest(url: url, authtoken: authtoken, shouldCache: false)
        let _ = try await req.serializingData().value
    }

    func markMessageRead(account: Account, messageID: Int) async throws {
        return try await markMessageAction(account: account, messageID: messageID, action: "mark_read")
    }

    func markMessageUnread(account: Account, messageID: Int) async throws {
        return try await markMessageAction(account: account, messageID: messageID, action: "mark_unread")
    }

    func markMessageDeleted(account: Account, messageID: Int) async throws {
        return try await markMessageAction(account: account, messageID: messageID, action: "mark_deleted")
    }

    //MARK: - Charges (Fines)

    func fetchPatronCharges(account: Account) async throws -> PatronCharges{
        print("\(Utils.tt) loadPatronCharges")
        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }

        // first fetch the fines summary
        let summaryReq = Gateway.makeRequest(service: API.actor, method: API.finesSummary, args: [authtoken, account.userID], shouldCache: false)
        let summary = try await summaryReq.gatewayResponseAsync().asObjectOrNil()
        if summary == nil {
            // no fines
            return PatronCharges(totalCharges: 0.0, totalPaid: 0.0, balanceOwed: 0.0, transactions: [])
        }

        // then fetch the transactions
        let transactionsReq = Gateway.makeRequest(service: API.actor, method: API.transactionsWithCharges, args: [authtoken, account.userID], shouldCache: false)
        let transactions = try await transactionsReq.gatewayResponseAsync().asArray()
        let charges = PatronCharges(
            totalCharges: summary?.getDouble("total_owed") ?? 0.0,
            totalPaid: summary?.getDouble("total_paid") ?? 0.0,
            balanceOwed: summary?.getDouble("balance_owed") ?? 0.0,
            transactions: FineRecord.makeArray(transactions))
        return charges
    }
}
