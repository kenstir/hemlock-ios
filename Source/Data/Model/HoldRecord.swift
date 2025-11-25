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

protocol HoldRecord {
    var id: Int { get }
    var target: Int? { get }
    var title: String { get }
    var author: String { get }
    var format: String { get }
    var status: String { get }
    var holdType: String? { get }
    var hasEmailNotify: Bool? { get }
    var hasPhoneNotify: Bool? { get }
    var phoneNotify: String? { get }
    var hasSmsNotify: Bool? { get }
    var smsNotify: String? { get }
    var smsCarrier: Int? { get }
    var pickupOrgId: Int? { get }
    var expireDate: Date? { get }
    var thawDate: Date? { get }
    var isSuspended: Bool? { get }
    var record: BibRecord? { get }
}
