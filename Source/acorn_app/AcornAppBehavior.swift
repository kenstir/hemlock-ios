//
//  AcornAppBehavior.swift
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

class AcornAppBehavior: AppBehavior {
    
    func isOnlineResource(record: MBRecord) -> Bool {
        if let item_form = record.mvrObj?.getString("item_form"), item_form == "o" {
            return true
        }
        if let item_form = record.attrs?["item_form"] {
            if item_form == "o" {
                return true
            }
        }
        return false
    }
    
    func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        if let datafields = record.marcRecord?.datafields {
            for datafield in datafields {
                // Include only certain 856 records where subfield 9 contains the library short code
                if datafield.tag == "856" && datafield.ind1 == "4" && (datafield.ind2 == "0" || datafield.ind2 == "1"),
                    datafield.subfields.contains(where: { $0.code == "9" && $0.text == orgShortName }),
                    let href = datafield.subfields.first(where: { $0.code == "u" })?.text,
                    let text = datafield.subfields.first(where: { $0.code == "3" || $0.code == "y" })?.text
                {
                    // Trim the link text for a better mobile UX
                    let trimmedText = text.replacingOccurrences(of: "Click here to download.", with: "").trim().trimTrailing(".")
                    links.append(Link(href: href, text: trimmedText))
                }
            }
        }
        return links
    }
}
