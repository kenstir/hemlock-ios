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

class AppState {
    class Key {
        static let searchClass = "searchClass"
        static let searchFormat = "searchFormat"
        static let searchOrg = "searchOrg"
    }

    static func getString(forKey key: String) -> String? {
        if let value = App.valet.string(forKey: key) {
            print("[pref] Got \(key) = \(value)")
            return value
        }
        return nil
    }

    static func setString(forKey key: String, value: String) {
        print("[pref] Set \(key) to \(value)")
        App.valet.set(string: value, forKey: key)
    }
}
