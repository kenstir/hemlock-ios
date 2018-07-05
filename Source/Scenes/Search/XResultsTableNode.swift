//
//  XResultsTableNode.swift
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

class XResultsTableNode: ASCellNode {
    
    //MARK: - Properties
    
    private let record: ResultRecord
    
    private let titleNode: ASTextNode
    private let authorNode: ASTextNode
    private let formatNode: ASTextNode
    private let separatorNode: ASDisplayNode
    
    //MARK: - Lifecycle
    
    init(record: ResultRecord) {
        self.record = record

        titleNode = ASTextNode()
        authorNode = ASTextNode()
        formatNode = ASTextNode()
        separatorNode = ASDisplayNode()

        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    //MARK: - Setup
    
    private func setupNodes() {
        self.setupTitleNode()
        self.setupAuthorNode()
        self.setupFormatNode()
        self.setupSeparatorNode()
    }
    
    private func setupTitleNode() {
        self.titleNode.attributedText = NSAttributedString(string: record.title, attributes: self.titleTextAttributes())
        self.titleNode.maximumNumberOfLines = 2
        self.titleNode.truncationMode = .byWordWrapping
    }
    
    private var titleTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)]
    }
    
    private func setupAuthorNode() {
        self.authorNode.attributedText = NSAttributedString(string: record.author, attributes: self.authorTextAttributes())
        self.authorNode.maximumNumberOfLines = 1
        self.authorNode.truncationMode = .byTruncatingTail
    }
    
    private var authorTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]
    }
    
    private func setupFormatNode() {
        self.formatNode.attributedText = NSAttributedString(string: record.author, attributes: self.authorTextAttributes())
        self.authorNode.maximumNumberOfLines = 1
        self.authorNode.truncationMode = .byTruncatingTail
    }
    
    private var formatTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12)]
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
