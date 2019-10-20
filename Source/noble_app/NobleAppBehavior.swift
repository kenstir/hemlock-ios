//
//  NobleAppBehavior.swift
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

class NobleAppBehavior: BaseAppBehavior {
    override init() {
        super.init()
        customStrings = [
            "button_pay_fines": "Pay all charges",
            "Fines": "Charges",
            "total_owed": "",
            "total_paid": "",
            "balance_owed": "Charges"
        ]
    }
    
    override func isOnlineResource(record: MBRecord) -> Bool {
        if let item_form = record.attrs?["item_form"] {
            if item_form == "q" || item_form == "o" || item_form == "s" {
                return true
            }
        }
        return false
    }
    
    // TODO: Check all levels between orgShortName and consortium.  In practice, it seems
    // electronic items are avaialable to either the branch or the corsortium, so this is Good Enough.
    // See also Located URIs in docs/cataloging/cataloging_electronic_resources.adoc
    func isAvailableToOrg(_ datafield: MARCDatafield, orgShortName: String?, consortiumShortName: String?) -> Bool {
        return datafield.subfields.contains(where: {
            $0.code == "9" && (orgShortName == nil || $0.text == orgShortName || $0.text == consortiumShortName)
        })
    }
    
    // Trim the link text for a better mobile UX
    func trimLinkText(_ s: String) -> String {
        // haven't seen the need for trimming yet in the NOBLE catalog
        return s
    }

    override func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        let consortiumShortName = Organization.consortium()?.shortname
        var links: [Link] = []
        var seen: Set<String> = []
        if let datafields = record.marcRecord?.datafields {
            for datafield in datafields {
                if datafield.isOnlineLocation,
                    let href = datafield.uri,
                    let text = datafield.linkText,
                    isAvailableToOrg(datafield, orgShortName: orgShortName, consortiumShortName: consortiumShortName)
                {
                    // Do not show the same URL twice
                    if !seen.contains(href) {
                        links.append(Link(href: href, text: trimLinkText(text)))
                        seen.insert(href)
                    }
                }
            }
        }
        return links
    }
}
