//
//  Copyright (C) 2018 Kenneth H. Cox
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
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation

class OrgType {
    static var orgTypes: [OrgType] = []

    let id: Int
    let name: String
    let label: String
    let canHaveUsers: Bool
    let canHaveVols: Bool

    var areSettingsLoaded = false

    init(id: Int, name: String, label: String, canHaveUsers: Bool, canHaveVols: Bool) {
        self.id = id
        self.name = name
        self.label = label
        self.canHaveUsers = canHaveUsers
        self.canHaveVols = canHaveVols
    }
    
    static func makeArray(_ objects: [OSRFObject]) -> [OrgType] {
        var orgTypes: [OrgType] = []
        for obj in objects {
            if let id = obj.getInt("id"),
                let name = obj.getString("name"),
                let label = obj.getString("opac_label"),
                let canHaveUsers = obj.getBool("can_have_users"),
                let canHaveVols = obj.getBool("can_have_vols")
            {
                orgTypes.append(OrgType(id: id, name: name, label: label, canHaveUsers: canHaveUsers, canHaveVols: canHaveVols))
            }
        }
        return orgTypes
    }
    
    static func loadOrgTypes(fromArray objects: [OSRFObject]) {
        orgTypes = OrgType.makeArray(objects)
    }
    
    static func find(byId id: Int) -> OrgType? {
        if let orgType = orgTypes.first(where: { $0.id == id }) {
            return orgType
        }
        return nil
    }
}

class Organization {
    static private var orgs: [Organization] = []
    static var isSMSEnabledSetting = false
    static var consortiumOrgID = 1 // as defaulted in Open-ILS code
    static var visibleOrgs: [Organization] {
        return Organization.orgs.compactMap { $0.opacVisible ? $0 : nil }
    }

    let id: Int
    let level: Int
    let name: String
    let shortname: String
    let ouType: Int
    let opacVisible: Bool
    let parent: Int?
    let addressID: Int?
    let email: String?
    let phoneNumber: String?
    
    var addressObj: OSRFObject? = nil

    var areSettingsLoaded = false
    var isPickupLocationSetting: Bool?
    var isPaymentAllowedSetting: Bool?
    var infoURL: String?
    var isPickupLocation: Bool {
        if let val = isPickupLocationSetting {
            return val
        }
        if let canHaveVols = orgType?.canHaveVols {
            return canHaveVols
        }
        return true // should not happen
    }
    var orgType: OrgType? {
        return OrgType.find(byId: ouType)
    }
    var spinnerLabel: String {
        if App.config.enableHierarchicalOrgTree {
            return String(repeating: "   ", count: level) + name
        } else {
            return name
        }
    }

    init(id: Int, level: Int, name: String, shortname: String, ouType: Int, opacVisible: Bool, aouObj obj: OSRFObject) {
        // required fields are direct params
        self.id = id
        self.level = level
        self.name = name
        self.shortname = shortname
        self.ouType = ouType
        self.opacVisible = opacVisible

        // optional fields are read from the aou obj
        self.parent = obj.getInt("parent_ou")
        self.addressID = obj.getInt("mailing_address")
        self.email = obj.getString("email")
        self.phoneNumber = obj.getString("phone")
    }
    
    // An org unit setting (ous) is an OSRFObject with "org" and "value" fields
    static func ousGetBool(_ obj: OSRFObject, _ setting: String) -> Bool? {
        if let valueObj = obj.getObject(setting),
            let value = valueObj.getBool("value")
        {
            return value
        }
        return nil
    }
    
    static func ousGetString(_ obj: OSRFObject, _ setting: String) -> String? {
        if let valueObj = obj.getObject(setting),
            let value = valueObj.getString("value")
        {
            return value
        }
        return nil
    }
    
    func loadSettings(fromObj obj: OSRFObject)  {
        if let val = Organization.ousGetBool(obj, API.settingCreditPaymentsAllow) {
            self.isPaymentAllowedSetting = val
        }
        if let val = Organization.ousGetBool(obj, API.settingNotPickupLib) {
            self.isPickupLocationSetting = !val
        }
        if let val = Organization.ousGetString(obj, API.settingInfoURL) {
            self.infoURL = val
        }
        if let val = Organization.ousGetBool(obj, API.settingSMSEnable) {
            // this setting is only queried on the top-level org
            Organization.isSMSEnabledSetting = val
        }
        self.areSettingsLoaded = true
    }

    static func find(byName name: String?) -> Organization? {
        if let org = orgs.first(where: { $0.name == name }) {
            return org
        }
        return nil
    }
    
    static func find(byShortName shortname: String?) -> Organization? {
        if let org = orgs.first(where: { $0.shortname == shortname }) {
            return org
        }
        return nil
    }

    static func find(byId id: Int?) -> Organization? {
        if let org = orgs.first(where: { $0.id == id }) {
            return org
        }
        return nil
    }
    
    static func consortium() -> Organization? {
        return find(byId: consortiumOrgID)
    }
    
    static func ancestors(byShortName shortname: String?) -> [String] {
        var shortnames: [String] = []
        var org: Organization? = find(byShortName: shortname)
        while let o = org {
            shortnames.append(o.shortname)
            org = find(byId: o.parent)
        }
        return shortnames
    }

    static func getSpinnerLabels() -> [String] {
        return orgs.compactMap { $0.opacVisible ? $0.spinnerLabel : nil }
    }
    
    static func getIsPickupLocation() -> [Bool] {
        return orgs.compactMap { $0.opacVisible ? $0.isPickupLocation : nil }
    }
    
    static func getIsPrimary() -> [Bool] {
        return orgs.compactMap {
            if $0.opacVisible {
                if let canHaveUsers = $0.orgType?.canHaveUsers {
                    return !canHaveUsers
                } else {
                    return true
                }
            } else {
                return nil
            }
        }
    }

    static func getShortName(forName name: String?) -> String? {
        if let org = orgs.first(where: { $0.name == name }) {
            return org.shortname
        }
        return nil
    }
    
    static func loadOrganizations(fromObj obj: OSRFObject) throws -> Void {
        orgs = []
        try addOrganization(obj, level: 0)
        
        if App.config.enableHierarchicalOrgTree {
            // orgs are already sorted by hierarchy
        } else {
            // sort orgs by name, except consortium comes first
            self.orgs.sort {
                if $0.id == 1 {
                    return true
                } else if $1.id == 1 {
                    return false
                }
                return $0.name < $1.name
            }
        }
    }

    static func addOrganization(_ obj: OSRFObject, level: Int) throws -> Void {
        guard let id = obj.getInt("id"),
            let name = obj.getString("name"),
            let shortname = obj.getString("shortname"),
            let ouType = obj.getInt("ou_type"),
            let opacVisible = obj.getBool("opac_visible") else
        {
            throw HemlockError.unexpectedNetworkResponse("decoding org tree")
        }
        let org = Organization(id: id, level: level, name: name.trim(), shortname: shortname.trim(), ouType: ouType, opacVisible: opacVisible, aouObj: obj)
        self.orgs.append(org)
        print("xxx.org_added id=\(id) level=\(level) vis=\(opacVisible) site=\(shortname) name=\(name)")

        if let children = obj.getAny("children") {
            if let childObjArray = children as? [OSRFObject] {
                for child in childObjArray {
                    let childLevel = opacVisible ? level + 1 : level
                    try addOrganization(child, level: childLevel)
                }
            }
        }
    }
    
    static func updateOrg(fromObj obj: OSRFObject) -> Void {
        guard let id = obj.getInt("id"),
            let name = obj.getString("name"),
            let shortname = obj.getString("shortname"),
            let ouType = obj.getInt("ou_type"),
            let opacVisible = obj.getBool("opac_visible") else
        {
            return
        }
        guard let index = orgs.firstIndex(where: { $0.id == id } ) else {
            return
        }
        let oldOrg = orgs[index]
        let newOrg = Organization(id: id, level: oldOrg.level, name: name.trim(), shortname: shortname.trim(), ouType: ouType, opacVisible: opacVisible, aouObj: obj)
        orgs[index] = newOrg
        print("xxx.org_update id=\(id) level=\(newOrg.level) vis=\(opacVisible) site=\(shortname) name=\(name)")
    }
}
