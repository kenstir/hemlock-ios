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

class AcornAppBehavior: BaseAppBehavior {
    override func isOnlineResource(record: MBRecord) -> Bool {
        if let item_form = record.attrs?["item_form"] {
            if item_form == "o" {
                return true
            }
        }
        
        // NB: Checking for item_form="o" fails to identify some online resources, e.g.
        // https://acorn.biblio.org/eg/opac/record/2891957
        // so we use this check as a backstop
        return isOnlineFormatCode(record.attrs?["icon_format"])
    }
    
    func isOnlineFormatCode(_ iconFormatCode: String?) -> Bool {
        guard let code = iconFormatCode else {
            return false
        }
        let onlineFormatCodes = ["ebook","eaudio","evideo","emusic"]
        return onlineFormatCodes.contains(code)
    }
    
    // Trim the link text for a better mobile UX
    override func trimLinkText(_ text: String) -> String {
        return text.replacingOccurrences(of: "Click here to download.", with: "").trim().trimTrailing(".")
    }
    
    override func isVisibleToOrg(_ datafield: MARCDatafield, orgShortName: String?) -> Bool {
        return isVisibleViaLocatedURI(datafield, orgShortName: orgShortName);
    }

    override func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        return getOnlineLocationsFromMARC(record: record, forSearchOrg: orgShortName)
    }
}
