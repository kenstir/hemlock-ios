//
//  App.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
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
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation
import PromiseKit
import PMKAlamofire
import Valet
import os.log

class App {
    //MARK: - Properties

    // idea from https://developer.apple.com/documentation/swift/maintaining_state_in_your_apps
    /*
    enum State {
        case start
        case loggedOut(Library)
        case loggedIn(Library, Account)
        case sessionExpired(Library, Account)
    }
    var state: State = .start
    */
    
    static var theme: Theme!
    static var config: AppConfiguration!
    static var behavior: AppBehavior!
    static var library: Library?
    static var idlLoaded: Bool?
    static var account: Account?

    /// the URL of the JSON directory of library systems available for use in the Hemlock app
    static let directoryURL = "https://evergreen-ils.org/directory/libraries.json"

    /// the valet saves things in the iOS keychain
    static let valet = Valet.valet(with: Identifier(nonEmpty: "Hemlock")!, accessibility: .whenUnlockedThisDeviceOnly)

    /// the accountManager manages storage of accounts in valet
    static let accountManager = AccountManager(valet: valet)
    
    /// search scopes
    static let searchScopes = ["Keyword","Title","Author","Subject","Series"]

    //MARK: - Functions
    
    // Clear the active account and its credentials
    static func logout() {
        accountManager.remove(username: account?.username)
        account?.clear()
        unloadIDL()
    }
    
    // Clear the active account and switch credentials
    static func switchCredentials(storedAccount: StoredAccount?) {
        accountManager.setActive(account: storedAccount)
        account?.clear()
        unloadIDL()
    }
    
    static func unloadIDL() {
        App.idlLoaded = false
    }

    static func fetchIDL() -> Promise<Void> {
        if App.idlLoaded ?? false {
            return Promise<Void>()
        }
        let start = Date()

        // Load IDL without caching; IDL is not backward compatible
        // across server upgrades.
        // TODO: use cache-busting URL so we can cache this
        //let req = Alamofire.request(Gateway.idlURL())
        var req: DataRequest
        do {
            req = try Alamofire.SessionManager.default
            .requestWithoutCache(Gateway.idlURL())
        } catch {
            // should not happen
            return Promise<Void> { _ in
                throw HemlockError.unexpectedNetworkResponse("unexpected error loading IDL: \(error.localizedDescription)")
            }
        }

        let promise = req.responseData().done { data, pmkresponse in
            let parser = IDLParser(data: data)
            App.idlLoaded = parser.parse()
            let elapsed = -start.timeIntervalSinceNow
            os_log("idl.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
        }
        return promise
    }
}
