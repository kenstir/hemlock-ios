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
import os.log

class EvergreenConsortiumService: ConsortiumService {
    var consortiumOrgID: Int { return Organization.consortiumOrgID }

    var isSmsEnabled: Bool { return Organization.isSMSEnabledSetting }

    var consortium: Organization? { return Organization.consortium() }

    var selectedOrganization: Organization? = nil

    var searchFormatSpinnerLabels: [String] { return CodedValueMap.searchFormatSpinnerLabels() }

    var searchFormatSpinnerValues: [String] { return CodedValueMap.searchFormatSpinnerValues() }

    var smsCarrierSpinnerLabels: [String] { return SMSCarrier.getSpinnerLabels() }

    var visibleOrgs: [Organization] { return Organization.visibleOrgs }

    var orgSpinnerLabels: [String] { return Organization.getSpinnerLabels() }

    var orgSpinnerShortNames: [String] { return Organization.getShortNames() }

    var orgSpinnerIsPrimaryFlags: [Bool] { return Organization.getIsPrimary() }

    func dumpOrgStats() {
        Organization.dumpOrgStats()
    }

    func find(byID id: Int?) -> Organization? {
        return Organization.find(byID: id)
    }

    func find(byShortName shortname: String?) -> Organization? {
        return Organization.find(byShortName: shortname)
    }

    func find(byName name: String?) -> Organization? {
        return Organization.find(byName: name)
    }
}
