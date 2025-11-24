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

/// require arg to be of specific concrete type or throw
func requireType<T>(_ value: Any) throws -> T {
    if let v = value as? T {
        return v
    }

    let expected = String(describing: T.self)
    let actual = String(describing: type(of: value))
    throw HemlockError.internalError("Type mismatch: expected \(expected), got \(actual)")
}
