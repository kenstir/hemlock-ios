//
//  XDetailsNode.swift
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

// mainly a copy of XResultsTableNode
// TODO: factor out commonality
class XDetailsNode: ASCellNode {
    
    //MARK: - Properties
    
    private let record: MBRecord
    
    private let pageHeaderNode: ASTextNode
    private let titleNode: ASTextNode
    private let spacerNode: ASDisplayNode
    private let authorNode: ASTextNode
    private let formatNode: ASTextNode
    private let imageNode: ASNetworkImageNode
    private let itemIndex: Int
    private let totalItems: Int
    
    //MARK: - Lifecycle
    
    init(record: MBRecord, index: Int, of totalItems: Int) {
        self.record = record
        self.itemIndex = index
        self.totalItems = totalItems

        pageHeaderNode = ASTextNode()
        titleNode = ASTextNode()
        spacerNode = ASDisplayNode()
        authorNode = ASTextNode()
        formatNode = ASTextNode()
        imageNode = ASNetworkImageNode()

        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    //MARK: - Setup
    
    private func setupNodes() {
        self.backgroundColor = UIColor.cyan
        self.setupPageHeaderNode()
        self.setupTitleNode()
        self.setupAuthorNode()
        self.setupFormatNode()
        self.setupImageNode()
        self.setupSpacerNode()
    }
    
    private func setupPageHeaderNode() {
        let naturalNumber = itemIndex + 1
        let str = "Item \(naturalNumber) of \(totalItems)"
        self.pageHeaderNode.attributedText = Style.makeTableHeaderString(str)
        self.pageHeaderNode.backgroundColor = App.theme.tableHeaderBackground
    }

    private func setupTitleNode() {
        self.titleNode.attributedText = Style.makeTitleString(record.title, ofSize: 18)
        self.titleNode.maximumNumberOfLines = 2
        self.titleNode.truncationMode = .byWordWrapping
    }
    
    private func setupAuthorNode() {
        self.authorNode.attributedText = Style.makeSubtitleString(record.author, ofSize: 16)
        self.authorNode.maximumNumberOfLines = 1
        self.authorNode.truncationMode = .byTruncatingTail
    }
    
    private func setupFormatNode() {
        self.formatNode.attributedText = Style.makeSubtitleString(record.format, ofSize: 16)
        self.formatNode.maximumNumberOfLines = 1
        self.formatNode.truncationMode = .byTruncatingTail
    }
    
    private func setupImageNode() {
        let url = AppSettings.url + "/opac/extras/ac/jacket/medium/r/" + String(record.id)
        self.imageNode.contentMode = .scaleAspectFit 
        self.imageNode.url = URL(string: url)
    }
    
    private func setupSpacerNode() {
        //self.spacerNode.backgroundColor = UIColor.red
    }
    
    //MARK: - Build node hierarchy
    
    private func buildNodeHierarchy() {
        self.addSubnode(pageHeaderNode)
        self.addSubnode(titleNode)
        self.addSubnode(spacerNode)
        self.addSubnode(authorNode)
        self.addSubnode(formatNode)
        self.addSubnode(imageNode)
    }
    
    //MARK: - Layout
    
    override func layout() {
        super.layout()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // header
        let headerSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0), child: pageHeaderNode)

        // summary + image
        let imageWidth = 100.0
        let imageHeight = imageWidth * 1.6
        
        let lhsSpec = ASStackLayoutSpec.vertical()
        lhsSpec.style.flexShrink = 1.0
        lhsSpec.style.flexGrow = 1.0
        lhsSpec.style.preferredSize = CGSize(width: 0, height: imageHeight)
        spacerNode.style.flexShrink = 1.0
        spacerNode.style.flexGrow = 1.0
        lhsSpec.children = [titleNode, spacerNode, authorNode, formatNode]
        
        imageNode.style.preferredSize = CGSize(width: imageWidth, height: imageHeight)

        let rhsSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [imageNode])
        
        let summaryRowSpec = ASStackLayoutSpec(direction: .horizontal,
                                        spacing: 8,
                                        justifyContent: .start,
                                        alignItems: .center,
                                        children: [lhsSpec, rhsSpec])
        //return summaryRowSpec
        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.style.flexShrink = 1.0
        pageSpec.style.flexGrow = 1.0
        //pageSpec.children = [headerSpec, summaryRowSpec]
        pageSpec.children = [summaryRowSpec]

        print(pageSpec.asciiArtString())
        return pageSpec
    }

}
