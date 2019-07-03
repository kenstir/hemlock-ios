//
//  MARCParser.swift
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

class MARCParser: NSObject, XMLParserDelegate {
    var parser: XMLParser?
    var error: Error?
    var currentDatafield: MARCDatafield?
    
    //MARK: - initializers
    
    init(contentsOf: URL) {
        parser = XMLParser(contentsOf: contentsOf)
    }
    
    init(data: Data) {
        parser = XMLParser(data: data)
    }
    
    //MARK: other methods
    
    func parse() -> Bool {
        guard let parser = self.parser else {
            return false
        }
        parser.delegate = self
        return parser.parse()
    }
    
    //MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String : String]) {
        print("didStartElement \(elementName)")
        if elementName == "datafield" {
            if let tag = attributes["tag"],
                let ind1 = attributes["ind1"],
                let ind2 = attributes["ind2"],
                tag == "856" && ind1 == "4" && (ind2 == "0" || ind2 == "1")
            {
                currentDatafield = MARCDatafield(tag: tag, ind1: ind1, ind2: ind2)
            }
        } else if elementName == "subfield" {
            if let datafield = currentDatafield,
                let code = attributes["code"]
            {
                debugPrint("here")
                //if code == "3" { datafield.materials = }
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("didEndElement \(elementName)")
        print("")
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print("foundCharacters \(string)")
        print("")
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        error = parseError
    }
}
