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

    /// the credentialManager manages storage of credentials in valet
    static let credentialManager = CredentialManager(valet: valet)
    
    /// search scopes
    static let searchScopes = ["Keyword","Title","Author","Subject","Series"]

    //MARK: - Functions
    
    // Clear the active account and its credentials
    static func logout() {
        credentialManager.removeCredential(forUsername: account?.username)
        account?.clear()
        unloadIDL()
    }
    
    // Clear the active account and switch credentials
    static func switchCredential(credential: Credential?) {
        credentialManager.setActive(credential: credential)
        account?.clear()
        //unloadIDL()  // I do not see why we would want to do this here
    }
    
    static func unloadIDL() {
        App.idlLoaded = false
    }

    static func fetchIDL() -> Promise<Void> {
        if App.idlLoaded ?? false {
            return Promise<Void>()
        }
        let start = Date()

        // Fetch IDL and parse it.
        let req = Gateway.makeRequest(url: Gateway.idlURL(), shouldCache: true)
        let promise = req.responseData().done { data, pmkresponse in
            let parser = IDLParser(data: data)
            App.idlLoaded = parser.parse()
            let elapsed = -start.timeIntervalSinceNow
            App.addElapsed(elapsed)
            os_log("idl.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
        }
        return promise
    }
    
    static var totalElapsed = 0.0
    @discardableResult
    static func addElapsed(_ elapsed: Double) -> Double {
        totalElapsed += elapsed
        return totalElapsed
    }
}
