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
    static var account: Account?
    static var fcmNotificationToken: String?
    static var launchCount: Int = 0
    static var launchNotificationUserInfo: [AnyHashable: Any]?

    /// TODO: make this injectable
    static var serviceConfig: ServiceConfig = EvergreenServiceConfig()

    /// the valet saves things in the iOS keychain
    static let valet = Valet.valet(with: Identifier(nonEmpty: "Hemlock")!, accessibility: .whenUnlockedThisDeviceOnly)

    /// the credentialManager manages storage of credentials in valet
    static let credentialManager = CredentialManager(valet: valet)

    //MARK: - Functions

    // Clear the active account and its credentials
    static func logout() {
        credentialManager.removeCredential(forUsername: account?.username)
        account?.clear()
    }

    // Clear the active account and switch credentials
    static func switchCredential(credential: Credential?) {
        credentialManager.setActive(credential: credential)
        account?.clear()
    }

    static func printLaunchInfo() {
        if let userInfo = launchNotificationUserInfo {
            let pn = PushNotification(userInfo: userInfo)
            print("[fcm] pn: \(pn)")
        }
        print("")
    }

    static func updateLaunchCount() {
        if let str = valet.string(forKey: "launchCount"),
           let val = Int(str) {
            launchCount = val + 1
        } else {
            launchCount = 1
        }
        valet.set(string: String(launchCount), forKey: "launchCount")
    }
}
