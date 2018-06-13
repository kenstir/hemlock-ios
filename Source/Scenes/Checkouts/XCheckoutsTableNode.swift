//
//  XCheckoutsTableNode.swift
//  X is for teXture
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

class XCheckoutsTableNode: ASCellNode {
    
    //MARK: - Properties
    
    private let circRecord: CircRecord
    
    private let titleNode: ASTextNode
    private let authorNode: ASTextNode
    private let separatorNode: ASDisplayNode
    
    //MARK: - Lifecycle
    
    init(circRecord: CircRecord) {
        self.circRecord = circRecord
        
        titleNode = ASTextNode()
        authorNode = ASTextNode()
        separatorNode = ASDisplayNode()
        
        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    //MARK: - Setup
    
    private func setupNodes() {
        self.setupTitleNode()
        self.setupAuthorNode()
        self.setupSeparatorNode()
    }
    
    private func setupTitleNode() {
        self.titleNode.attributedText = NSAttributedString(string: self.circRecord.title, attributes: self.titleTextAttributes())
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
    }
    
    private var titleTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)]
    }
    
    private func setupAuthorNode() {
        self.authorNode.attributedText = NSAttributedString(string: self.circRecord.author, attributes: self.authorTextAttributes())
        self.authorNode.maximumNumberOfLines = 1
        self.authorNode.truncationMode = .byTruncatingTail
    }
    
    private var authorTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]
    }

    private func setupSeparatorNode() {
        self.separatorNode.backgroundColor = UIColor.lightGray
    }
    
    //MARK: - Build node hierarchy
    
    private func buildNodeHierarchy() {
        self.addSubnode(titleNode)
        self.addSubnode(authorNode)
        self.addSubnode(separatorNode)
    }
    
    //MARK: - Layout
    
    override func layout() {
        super.layout()
        let separatorHeight = 1 / UIScreen.main.scale
        self.separatorNode.frame = CGRect(x: 0.0, y: 0.0, width: self.calculatedSize.width, height: separatorHeight)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let detailsSpec = ASStackLayoutSpec.vertical()
        detailsSpec.style.flexShrink = 1.0
        detailsSpec.style.flexGrow = 1.0
        detailsSpec.children = [titleNode, authorNode]
        
        let contentsSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 40, justifyContent: .start, alignItems: .center, children: [detailsSpec])

        return ASInsetLayoutSpec(insets: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0), child: contentsSpec)
    }
    
}
