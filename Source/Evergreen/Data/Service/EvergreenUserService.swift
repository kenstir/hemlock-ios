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
