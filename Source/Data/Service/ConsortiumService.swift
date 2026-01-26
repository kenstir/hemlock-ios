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
    var consortiumOrgID: Int { get }

    /// is SMS notifications enabled for all orgs?
    var isSmsEnabled: Bool { get }

    /// org at the highest scope
    var consortium: Organization? { get }

    /// last searched organization
    var selectedOrganization: Organization? { get }

    /// search format option labels
    var searchFormatSpinnerLabels: [String] { get }

    /// search format option values; parallel array to `searchFormatSpinnerLabels`
    var searchFormatSpinnerValues: [String] { get }

    /// SMS carrier option labels
    var smsCarrierSpinnerLabels: [String] { get }

    /// all visible organizations
    var visibleOrgs: [Organization] { get }

    /// visible organizations labels for use when selecting an org
    var orgSpinnerLabels: [String] { get }

    /// org short names; parallel array to `orgSpinnerLabels`
    var orgSpinnerShortNames: [String] { get }

    /// whether each org is a pickup location; parallel array to `orgSpinnerLabels`
    var orgSpinnerIsPickupLocationFlags: [Bool] { get }

    /// whether each org is primary (bold); parallel array to `orgSpinnerLabels`
    var orgSpinnerIsPrimaryFlags: [Bool] { get }

    /// Logs details about all loaded orgs for debugging
    func dumpOrgStats() -> Void

    /// find an organization by its ID
    func find(byID id: Int?) -> Organization?

    /// find an organization by its short name
    func find(byShortName shortname: String?) -> Organization?

    /// find an organization by its full name
    func find(byName name: String?) -> Organization?
}
