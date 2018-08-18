//
//  Organization.swift
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
    static var orgs: [Organization] = []
    static var isSMSEnabledSetting = false
    static var consortiumOrgID = 1 // as defaulted in Open-ILS code

    var id: Int
    var level: Int
    var name: String
    var shortname: String
    var parent: Int?
    var ouType: Int
    
    var areSettingsLoaded = false
    var isPickupLocationSetting: Bool?
    var isPaymentAllowedSetting: Bool?
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

    init(id: Int, level: Int, name: String, shortname: String, parent: Int?, ouType: Int) {
        self.id = id
        self.level = level
        self.name = name
        self.shortname = shortname
        self.parent = parent
        self.ouType = ouType
    }
    
    static func parseBoolSetting(_ obj: OSRFObject, _ setting: String) -> Bool? {
        if let valueObj = obj.getObject(setting),
            let value = valueObj.getBool("value")
        {
            return value
        }
        return nil
    }
    
    func loadSettings(fromObj obj: OSRFObject)  {
        if let val = Organization.parseBoolSetting(obj, API.settingCreditPaymentsAllow) {
            self.isPaymentAllowedSetting = val
        }
        if let val = Organization.parseBoolSetting(obj, API.settingNotPickupLib) {
            self.isPickupLocationSetting = !val
        }
        if let val = Organization.parseBoolSetting(obj, API.settingSMSEnable) {
            // this setting is only queried on the top-level org
            Organization.isSMSEnabledSetting = val
        }
        self.areSettingsLoaded = true
    }
    
    static func find(byName name: String) -> Organization? {
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

    static func find(byId id: Int) -> Organization? {
        if let org = orgs.first(where: { $0.id == id }) {
            return org
        }
        return nil
    }
    
//    static func consortium() -> Organization? {
//        return orgs.first(where: { $0.parent == nil })
//    }

    static func getSpinnerLabels() -> [String] {
        //return orgs.map { $0.name }
        return orgs.map { String(repeating: "   ", count: $0.level) + $0.name }
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
    }
    
    static func addOrganization(_ obj: OSRFObject, level: Int) throws -> Void {
        let parent = obj.getInt("parent_ou")
        guard let id = obj.getInt("id"),
            let name = obj.getString("name"),
            let shortname = obj.getString("shortname"),
            let ouType = obj.getInt("ou_type"),
            let opacVisible = obj.getBool("opac_visible") else
        {
            throw HemlockError.unexpectedNetworkResponse("decoding orginization tree")
        }
        print("xxx id=\(id) level=\(level) vis=\(opacVisible) site=\(shortname) name=\(name)")
        if opacVisible {
            let org = Organization(id: id, level: level, name: name.trim(), shortname: shortname.trim(), parent: parent, ouType: ouType)
            self.orgs.append(org)
        }
        if let children = obj.getAny("children") {
            if let childObjArray = children as? [OSRFObject] {
                for child in childObjArray {
                    try addOrganization(child, level: level + 1)
                }
            }
        }
    }
}
