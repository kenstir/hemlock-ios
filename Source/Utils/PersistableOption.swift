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

protocol PersistableOption {
    /// the key used to persist the value
    var key: String { get }

    /// title of the option in the UI
    var title: String { get }

    /// description of the option in the UI, i.e. the label describing the selected value
    var description: String { get }

    /// value of the option used in the app and stored in persistence
    associatedtype Value: Codable

    var defaultValue: Value { get }

    var value: Value { get set }

    /// loads ``value`` from persistence if available, otherwise ``defaultValue``
    func load() -> Void

    /// saves ``value`` to persistence
    func save() -> Void
}

/// a PersistableOption that facilitates using ``OptionsViewController`` to choose one of the available string values
class StringOption: PersistableOption {
    let key: String
    let title: String
    var description: String

    typealias Value = String

    let optionLabels: [String]
    let optionValues: [String]
    let optionIsEnabled: [Bool]
    let optionIsPrimary: [Bool]

    let defaultValue: String
    var value: String
    var selectedIndex: Int = 0

    init(key: String, title: String, defaultValue: String, optionLabels: [String], optionValues: [String] = [], optionIsEnabled: [Bool] = [], optionIsPrimary: [Bool] = []) {
        assert(!optionLabels.isEmpty, "optionLabels must not be empty")
        self.key = key
        self.title = title
        self.defaultValue = defaultValue
        self.value = defaultValue
        self.optionLabels = optionLabels
        self.optionValues = optionValues
        self.optionIsEnabled = optionIsEnabled
        self.optionIsPrimary = optionIsPrimary
        self.description = ""
    }

    func load() {
        if let value = UserDefaults.standard.string(forKey: key) {
            select(byValue: value)
        } else {
            select(byValue: defaultValue)
        }
    }

    func save() {
        UserDefaults.standard.set(self.value, forKey: key)
    }

    func select(byValue selectedValue: String) {
        let values = (optionValues.isEmpty ? optionLabels : optionValues)
        value = selectedValue
        selectedIndex = values.firstIndex(of: value) ?? 0
        description = optionLabels[selectedIndex].trim()
    }
}
