//
//  XUtils.swift
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
import AsyncDisplayKit

class XUtils {
    static func makeDisclosureNode() -> ASDisplayNode {
        let node = ASDisplayNode { () -> UIView in
            let disclosure = UITableViewCell()
            disclosure.accessoryType = .disclosureIndicator
            disclosure.backgroundColor = .clear
            disclosure.isUserInteractionEnabled = false
            disclosure.selectionStyle = .gray
            disclosure.tintColor = .darkGray
            return disclosure
        }
        node.style.preferredSize = CGSize(width: 27, height: 27)
        return node
    }
    
    static func makeSwitchNode() -> ASDisplayNode {
        let node = ASDisplayNode { () -> UIView in
            return UISwitch()
        }
        return node
    }
    
    static func makeTextFieldNode(ofSize size: CGFloat = 14) -> ASDisplayNode {
        let node = ASDisplayNode { () -> UIView in
            let textField = UITextField()
            textField.font = UIFont.systemFont(ofSize: size)
            return textField
        }
        return node
    }
    
    static func makeDisclosureOverlaySpec(_ node: ASDisplayNode, overlay: ASDisplayNode) -> ASLayoutSpec {
        let insetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: CGFloat.infinity, left: CGFloat.infinity, bottom: CGFloat.infinity, right: 0), child: overlay)
        let spec = ASOverlayLayoutSpec(child: node, overlay: insetSpec)
        spec.style.flexGrow = 1
        spec.style.flexShrink = 1
        return spec
    }
}
