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

class EvergreenAppBehavior: AppBehavior {

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

    func isOnlineResource(record: BibRecord) -> Bool {
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

    // Implements the isVisibleToOrg interface for catalogs that use Located URIs
    func isVisibleViaLocatedURI(_ datafield: MARCDatafield, orgShortName: String?) -> Bool {
        let ancestors = EvergreenOrganization.ancestors(byShortName: orgShortName)
        let subfield9s = datafield.subfields.filter({ $0.code == "9" })
        if subfield9s.count == 0 {
            return true
        }
        for subfield in subfield9s {
            if let shortname = subfield.text,
                ancestors.contains(shortname) {
                return true
            }
        }
        return false
    }

    func getOnlineLocationsFromMARC(record: BibRecord, forSearchOrg orgShortName: String?) -> [Link] {
        if let marcRecord = record.marcRecord {
            return getLinks(fromMarcRecord: marcRecord, forSearchOrg: orgShortName)
        }
        return []
    }

    func getLinks(fromMarcRecord marcRecord: MARCRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        for datafield in marcRecord.datafields {
            if datafield.isOnlineLocation,
                let href = datafield.uri,
                isVisibleToOrg(datafield, orgShortName: orgShortName)
            {
                let text = datafield.linkText ?? href
                // Filter duplicate links
                let link = Link(href: href.trim(), text: trimLinkText(text))
                if !links.contains(link) {
                    links.append(link)
                }
            }
        }

        // I don't know where I got the notion to sort these;
        // I don't see that done in the OPAC.
        //return links.sorted()
        return links
    }

    func onlineLocations(record: BibRecord, forSearchOrg orgShortName: String?) -> [Link] {
        var links: [Link] = []
        if let online_loc = record.firstOnlineLocation {
            links.append(Link(href: online_loc, text: ""))
        }
        return links
    }
}
