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

protocol Organization {
    var id: Int { get }
    var level: Int { get }
    var name: String { get }
    var shortname: String { get }
    var opacVisible: Bool { get }
    var parent: Int? { get }

    var hours: OrgHours? { get }
    var closures: [OrgClosure] { get }

    var email: String? { get }
    var phoneNumber: String? { get }
    var addressForNavigation: String? { get }
    var addressForLabelLine1: String? { get }
    var addressForLabelLine2: String? { get }
    var eresourcesURL: String? { get }
    var eventsURL: String? { get }
    var infoURL: String? { get }
    var meetingRoomsURL: String? { get }
    var museumPassesURL: String? { get }

    var spinnerLabel: String { get }
    var isPickupLocation: Bool { get }
    var canHaveUsers: Bool { get }
}
