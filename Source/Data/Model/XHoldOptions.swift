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

/// Options for placing a hold.
struct XHoldOptions {
    let holdType: String
    let notifyByEmail: Bool
    let phoneNotify: String?
    let smsNotify: String?
    let smsCarrierId: Int?
    let useOverride: Bool = false
    var pickupOrgId: Int
    var expirationDate: Date? = nil
    var suspended: Bool = false
    var thawDate: Date? = nil
}

/// Options for updating a hold
struct XHoldUpdateOptions {
    let notifyByEmail: Bool
    let phoneNotify: String?
    let smsNotify: String?
    let smsCarrierId: Int?
    let pickupOrgId: Int
    let expirationDate: Date?
    let suspended: Bool
    let thawDate: Date?
}
