//
//  MainButtonCellNode.swift
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

import AsyncDisplayKit
import Foundation

class MainButtonCellNode: ASDisplayNode {
    override required init() {
        super.init()
        automaticallyManagesSubnodes = true
        backgroundColor = .white
    }
    
    class func title() -> String {
        assertionFailure("no title")
        return ""
    }
    
    class func descriptionTitle() -> String? {
        return nil
    }
}

class ItemsCheckedOutButton: MainButtonCellNode {
    let titleNode     = ASTextNode()
//    let subHeadNode   = ASTextNode()

    required init() {
        super.init()
        
        let attrs = [NSAttributedStringKey.foregroundColor: UIColor.blue,
                     NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 20)]
        
        titleNode.attributedText = NSAttributedString(string: "blah blah", attributes: attrs)
        titleNode.maximumNumberOfLines = 1
        titleNode.truncationMode = .byTruncatingTail
        
//        subHeadNode.attributedText = NSAttributedString(string: "Sunset Beach, San Fransisco, CA", attributes: attrs)
//        subHeadNode.maximumNumberOfLines = 1
//        subHeadNode.truncationMode = .byTruncatingTail
    }
    
    override class func title() -> String {
        return "Items Checked Out"
    }
    
    override class func descriptionTitle() -> String? {
        return nil
    }

}
