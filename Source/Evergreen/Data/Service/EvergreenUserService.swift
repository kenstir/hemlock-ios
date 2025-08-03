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

class EvergreenUserService: XUserService {
    var tt: String {
        if Thread.isMainThread {
            return "[main ]"
        } else {
            let threadID = pthread_mach_thread_np(pthread_self())
            return "[\(threadID)]"
        }
    }

    func loadSession(account: Account) async throws {
        let req = Gateway.makeRequest(service: API.auth, method: API.authGetSession, args: [account.authtoken], shouldCache: false)
        let obj = try await req.gatewayResponseAsync().asObject()
        account.loadSession(fromObject: obj)

        try await loadUserSettings(account: account)
    }

    private func loadUserSettings(account: Account) async throws {
        let fields = ["card", "settings"]
        let req = Gateway.makeRequest(service: API.actor, method: API.userFleshedRetrieve, args: [account.authtoken, account.userID, fields], shouldCache: false)
        let obj = try await req.gatewayResponseAsync().asObject()
        account.loadUserSettings(fromObject: obj)
    }

    func deleteSession(account: Account) async throws {
        throw HemlockError.notImplemented
    }

    func loadPatronLists(account: Account) async throws {
        print("[async]\(tt) loadPatronLists")
        let req = Gateway.makeRequest(service: API.actor, method: API.containerRetrieveByClass, args: [account.authtoken, account.userID, API.containerClassBiblio, API.containerTypeBookbag], shouldCache: false)
        let objects = try await req.gatewayResponseAsync().asArray()
//        print("[async]\(tt) about to call account.loadBookBags(fromArray:)")
//        account.loadBookBags(fromArray: objects)
        await loadPatronListsSafe(account: account, fromArray: objects)
    }

    @MainActor
    func loadPatronListsSafe(account: Account, fromArray objects: [OSRFObject]) async {
        print("[async]\(tt) about to call account.loadBookBags(fromArray:)")
        account.loadBookBags(fromArray: objects)
    }

    func loadPatronListItems(account: Account, patronList: BookBag) async throws {
        print("[async]\(tt) \(patronList.id) loadPatronListItems")
        guard let authtoken = account.authtoken else {
            throw HemlockError.sessionExpired
        }
        let query = "container(bre,bookbag,\(patronList.id),\(authtoken))"
        let options = ["limit": 999]
        let queryReq = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 0], shouldCache: false)

        let allItemsReq = Gateway.makeRequest(service: API.actor, method: API.containerFlesh, args: [authtoken, API.containerClassBiblio, patronList.id], shouldCache: false)

        // await both
        let queryObj = try await queryReq.gatewayResponseAsync().asObject()
        let allItemsObj = try await allItemsReq.gatewayResponseAsync().asObject()

        // safely load results
        await loadPatronListItemsSafe(account: account, patronList: patronList, queryObj: queryObj, allItemsObj: allItemsObj)
    }

    @MainActor
    func loadPatronListItemsSafe(account: Account, patronList: BookBag, queryObj: OSRFObject, allItemsObj: OSRFObject) {
        print("[async]\(tt) \(patronList.id) about to call .loadItems()")
        patronList.initVisibleIds(fromQueryObj: queryObj)
        patronList.loadItems(fromFleshedObj: allItemsObj)
    }

    func createPatronList(account: Account, name: String, description: String) async throws {
        throw HemlockError.notImplemented
    }

    func deletePatronList(account: Account, listId: Int) async throws {
        throw HemlockError.notImplemented
    }

    func removeItemFromPatronList(account: Account, listId: Int, itemId: Int) async throws {
        throw HemlockError.notImplemented
    }


    func fetchPatronMessages(account: Account) async throws -> [PatronMessage] {
        let req = Gateway.makeRequest(service: API.actor, method: API.messagesRetrieve, args: [account.authtoken, account.userID], shouldCache: false)
        let objects = try await req.gatewayResponseAsync().asArray()
        return PatronMessage.makeArray(objects)
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
}
