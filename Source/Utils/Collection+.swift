//
//  Copyright (c) 2026 Kenneth H. Cox
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

extension RandomAccessCollection where Index == Int {
    /// Returns the first index where `predicate` is true, or `0` if none.
    func firstIndexOrZero(where predicate: (Element) -> Bool) -> Int {
        if let idx = firstIndex(where: predicate) {
            return idx
        }
        return 0
    }

    /// Returns the first index of `element`, or `0` if not found.
    func firstIndexOrZero(of element: Element) -> Int where Element: Equatable {
        if let idx = firstIndex(of: element) {
            return idx
        }
        return 0
    }
}
