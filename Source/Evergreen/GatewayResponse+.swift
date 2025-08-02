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

extension GatewayResponse {
    func asString() throws -> String {
        if let error = self.error {
            throw error
        } else if let str = self.str {
            return str
        } else {
            throw HemlockError.serverError("expected string, got \(self.description)")
        }
    }

    func asObject() throws -> OSRFObject {
        if let error = self.error {
            throw error
        } else if let obj = self.obj {
            return obj
        } else {
            throw HemlockError.serverError("expected object, got \(self.description)")
        }
    }

    func asArray() throws -> [OSRFObject] {
        if let error = self.error {
            throw error
        } else if let array = self.array {
            return array
        } else {
            throw HemlockError.serverError("expected array, got \(self.description)")
        }
    }
}
