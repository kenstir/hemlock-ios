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

    /// value of the option used in the app and stored in persistence
    associatedtype Value: Codable

    /// loads ``value`` from persistence if available, otherwise ``defaultValue``
    func load() -> Value

    /// saves ``value`` to persistence
    func save(_ value: Value) -> Void
}

/// a string option that facilitates using ``OptionsViewController`` to choose one of the available string values.
protocol SelectableOption {
    /// the set of (possibly padded) labels to display
    var optionLabels: [String] { get }

    /// the set of underlying values corresponding to each label if needed; may be empty
    var optionValues: [String] { get }

    /// if non-empty, indicates whether each option is enabled; if empty, all options are enabled
    var optionIsEnabled: [Bool] { get }

    /// if non-empty, indicates whether each option is displayed as primary, in a larger bold font; if empty, all options are normal font
    var optionIsPrimary: [Bool] { get }
}

/// a string option that facilitates using ``OptionsViewController`` to choose one of the available string values.
/// If ``key`` is non-empty, the value can be persisted using ``PersistableOption``.
class StringOption: PersistableOption, SelectableOption {
    typealias Value = String

    let key: String

    /// title of the option in the UI
    let title: String

    /// the set of (possibly padded) labels to display
    let optionLabels: [String]

    /// the set of underlying values corresponding to each label(if needed; may be empty
    let optionValues: [String]

    /// if non-empty, indicates whether each option is enabled; if empty, all options are enabled
    let optionIsEnabled: [Bool]

    /// if non-empty, indicates whether each option is displayed as primary, in a larger bold font; if empty, all options are normal font
    let optionIsPrimary: [Bool]

    /// default value of the option used in the app
    let defaultValue: String

    /// index of the selected option in option arrays
    var selectedIndex: Int = 0

    /// value of the option used in the app and stored in persistence
    var value: String {
        let values = (optionValues.isEmpty ? optionLabels : optionValues)
        return values[selectedIndex]
    }

    /// description of the option in the UI, i.e. the label describing the selected value
    var description: String {
        optionLabels[selectedIndex].trim()
    }

    init(key: String, title: String, defaultValue: String, optionLabels: [String], optionValues: [String] = [], optionIsEnabled: [Bool] = [], optionIsPrimary: [Bool] = []) {
        assert(!optionLabels.isEmpty, "optionLabels must not be empty")
        assert(optionValues.isEmpty || optionValues.count == optionLabels.count)
        assert(optionIsEnabled.isEmpty || optionIsEnabled.count == optionLabels.count)
        assert(optionIsPrimary.isEmpty || optionIsPrimary.count == optionLabels.count)
        assert(optionValues.contains(defaultValue) || optionLabels.contains(defaultValue))

        self.key = key
        self.title = title
        self.defaultValue = defaultValue
        self.optionLabels = optionLabels
        self.optionValues = optionValues
        self.optionIsEnabled = optionIsEnabled
        self.optionIsPrimary = optionIsPrimary

        select(byValue: defaultValue)
    }

    convenience init(key: String, title: String, defaultIndex: Int, optionLabels: [String], optionValues: [String] = [], optionIsEnabled: [Bool] = [], optionIsPrimary: [Bool] = []) {
        let defaultValue = (optionValues.isEmpty ? optionLabels[defaultIndex] : optionValues[defaultIndex])
        self.init(key: key, title: title, defaultValue: defaultValue, optionLabels: optionLabels, optionValues: optionValues, optionIsEnabled: optionIsEnabled, optionIsPrimary: optionIsPrimary)
    }

    func select(byValue selectedValue: String) {
        let values = (optionValues.isEmpty ? optionLabels : optionValues)
        selectedIndex = values.firstIndex(of: selectedValue) ?? 0
    }

    @discardableResult
    func load() -> String {
        if let storedValue = AppState.string(forKey: key) {
            select(byValue: storedValue)
        } else {
            select(byValue: defaultValue)
        }
        return self.value
    }

    internal func save(_ value: String) {
        AppState.set(string: value, forKey: key)
    }

    func save() {
        save(self.value)
    }
}
