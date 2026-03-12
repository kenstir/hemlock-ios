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

protocol Account: AnyObject {
    var username: String { get }
    var password: String { get }
    var authtoken: String? { get }
    var barcode: String? { get }
    var expireDateLabel: String? { get }
    var displayName: String { get }
    var phoneNumber: String? { get }
    var smsNumber: String? { get }

    var userID: Int? { get }
    var homeOrgID: Int? { get }
    var searchOrgID: Int? { get }
    var pickupOrgID: Int? { get }
    var smsCarrierID: Int? { get }

    var expireDate: Date? { get }

    var notifyByEmail: Bool { get }
    var notifyByPhone: Bool { get }
    var notifyBySMS: Bool { get }

    var patronLists: [any PatronList] { get }
    var patronListsEverLoaded: Bool { get }

    var circHistoryStart: String? { get set }
    var savedPushNotificationData: String? { get set }
    var savedPushNotificationEnabled: Bool { get set }

    func clear()
    func removePatronList(at index: Int)
}
