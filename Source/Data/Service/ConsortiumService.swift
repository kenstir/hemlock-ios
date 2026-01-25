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

protocol ConsortiumService {
    /// an ID to use for the consortium as a whole, when needed
    var consortiumId: Int { get }

    /// is SMS notifications enabled for all orgs?
    var isSmsEnabled: Bool { get }

    /// org at the highest scope
    var consortium: Organization? { get }

    /// last searched organization
    var selectedOrganization: Organization? { get }

    var visibleOrgs: [Organization] { get }

    /// Logs details about all loaded orgs for debugging
    func dumpOrgStats() -> Void

    func find(byId id: Int?) -> Organization?

    func find(byShortName shortname: String?) -> Organization?

    func find(byName name: String?) -> Organization?
}
