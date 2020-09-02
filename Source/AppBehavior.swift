//
//  AppBehavior.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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

protocol AppBehavior {
    func isOnlineResource(record: MBRecord) -> Bool
    func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link]
}

class BaseAppBehavior: AppBehavior {

    init() {
        MessageMap.loadFromResources()
    }
    
    fileprivate func isOnlineFormat(iconFormatLabel: String?) -> Bool {
        guard let label = iconFormatLabel else { return false }
        if label == "Picture" {
            return true
        }
        return label.hasPrefix("E-")
    }
    
    func isOnlineResource(record: MBRecord) -> Bool {
        if let item_form = record.attrs?["item_form"] {
            if item_form == "o" || item_form == "s" {
                return true
            }
        }
        
        return isOnlineFormat(iconFormatLabel: record.iconFormatLabel);
    }
    
    // Trim the link text for a better mobile UX
    func trimLinkText(_ s: String) -> String {
        return s
    }
    
    // Is this MARC datafield a URI visible to this org?
    func isVisibleToOrg(_ datafield: MARCDatafield, orgShortName: String?) -> Bool {
        return true;
    }
    
    // Implements the above interface for catalogs that use Located URIs
    func isVisibleViaLocatedURI(_ datafield: MARCDatafield, orgShortName: String?) -> Bool {
        let ancestors = Organization.ancestors(byShortName: orgShortName)
        for subfield in datafield.subfields {
            if subfield.code == "9",
                let shortname = subfield.text,
                ancestors.contains(shortname) {
                return true
            }
        }
        return false
    }

    func getOnlineLocationsFromMARC(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        if let datafields = record.marcRecord?.datafields {
            for datafield in datafields {
                if datafield.isOnlineLocation,
                    let href = datafield.uri,
                    let text = datafield.linkText,
                    isVisibleToOrg(datafield, orgShortName: orgShortName)
                {
                    // Filter duplicate links
                    let link = Link(href: href.trim(), text: trimLinkText(text))
                    if !links.contains(link) {
                        links.append(link)
                    }
                }
            }
        }
        return links.sorted()
    }

    func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        if let online_loc = record.firstOnlineLocationInMVR {
            links.append(Link(href: online_loc, text: ""))
        }
        return links
    }
}
