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

    static var library: Library?
    static var idlParserStatus: Bool?
    static var account: Account?

    /// the URL of the JSON directory of library systems available for use in the Hemlock app
    static let directoryURL = "https://evergreen-ils.org/directory/libraries.json"

    /// the valet saves things in the iOS keychain
    static let valet = Valet.valet(with: Identifier(nonEmpty: "Hemlock")!, accessibility: .whenUnlockedThisDeviceOnly)
}
