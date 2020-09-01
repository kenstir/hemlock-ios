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
    override func isOnlineResource(record: MBRecord) -> Bool {
        if let item_form = record.attrs?["item_form"] {
            if item_form == "o" || item_form == "s" {
                return true
            }
        }
        return false
    }
    
    // Don't filter URIs because the query already did.  For a good UX we show all URIs
    // located by the search and let the link text and the link itself controll access.
    // See also Located URIs in docs/cataloging/cataloging_electronic_resources.adoc
    override func isVisibleToOrg(_ datafield: MARCDatafield, orgShortName: String?) -> Bool {
        return true;
    }

    override func onlineLocations(record: MBRecord, forSearchOrg orgShortName: String?) -> [Link] {
        return getOnlineLocationsFromMARC(record: record, forSearchOrg: orgShortName)
    }
}
