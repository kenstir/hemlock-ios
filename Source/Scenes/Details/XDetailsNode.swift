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
    
    private let pageHeader: ASDisplayNode
    private let pageHeaderText: ASTextNode
    private let titleNode: ASTextNode
    private let spacerNode: ASDisplayNode
    private let authorNode: ASTextNode
    private let formatNode: ASTextNode
    private let publicationNode: ASTextNode
    private let imageNode: ASNetworkImageNode
    private let itemIndex: Int
    private let totalItems: Int
    
    //MARK: - Lifecycle
    
    init(record: MBRecord, index: Int, of totalItems: Int) {
        self.record = record
        self.itemIndex = index
        self.totalItems = totalItems

        pageHeader = ASDisplayNode()
        pageHeaderText = ASTextNode()
        titleNode = ASTextNode()
        spacerNode = ASDisplayNode()
        authorNode = ASTextNode()
        formatNode = ASTextNode()
        publicationNode = ASTextNode()
        imageNode = ASNetworkImageNode()

        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    //MARK: - Setup
    
    private func setupNodes() {
        self.setupPageHeader()
        self.setupTitle()
        self.setupTextNode(authorNode, str: record.author, ofSize: 16)
        self.setupTextNode(formatNode, str: record.format, ofSize: 16)
        self.setupTextNode(publicationNode, str: record.pubinfo, ofSize: 14)
        self.setupImageNode()
        self.setupSpacerNode()
    }
    
    private func setupPageHeader() {
        let naturalNumber = itemIndex + 1
        let str = "Item \(naturalNumber) of \(totalItems)"
        pageHeaderText.attributedText = Style.makeTableHeaderString(str)
        pageHeaderText.backgroundColor = UIColor.cyan
        pageHeader.backgroundColor = App.theme.tableHeaderBackground
    }

    private func setupTitle() {
        self.titleNode.attributedText = Style.makeTitleString(record.title, ofSize: 18)
        self.titleNode.maximumNumberOfLines = 2
        self.titleNode.truncationMode = .byWordWrapping
    }
    
    private func setupTextNode(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
        textNode.attributedText = Style.makeSubtitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 1
        textNode.truncationMode = .byTruncatingTail
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
        self.addSubnode(pageHeaderText)
        self.addSubnode(pageHeader)
        self.addSubnode(titleNode)
        self.addSubnode(spacerNode)
        self.addSubnode(authorNode)
        self.addSubnode(formatNode)
        self.addSubnode(publicationNode)
        self.addSubnode(imageNode)
    }
    
    //MARK: - Layout
    
    override func layout() {
        super.layout()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // header
        //works
//        pageHeader.style.preferredLayoutSize = ASLayoutSize(width: ASDimensionMake("100%"), height: ASDimensionMake(35))
//        let headerSpec = ASWrapperLayoutSpec(layoutElement: pageHeader)

        pageHeader.style.preferredSize = CGSize(width: constrainedSize.max.width, height: 35*3)
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let insetSpec = ASInsetLayoutSpec(insets: insets, child: pageHeaderText)
        let centerSpec = ASCenterLayoutSpec(centeringOptions: .X, sizingOptions: [], child: pageHeaderText)
        let headerSpec = ASOverlayLayoutSpec(child: pageHeader, overlay: centerSpec)

        // summary + image
        let imageWidth = 100.0
        let imageHeight = imageWidth * 1.6
        
        let lhsSpec = ASStackLayoutSpec.vertical()
        lhsSpec.spacing = 8.0
        lhsSpec.alignItems = .start
        lhsSpec.style.flexGrow = 1.0
        lhsSpec.children = [titleNode, authorNode, formatNode, publicationNode]

        imageNode.style.preferredSize = CGSize(width: imageWidth, height: imageHeight)

        let rhsSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [imageNode])
        
        let summaryRowSpec = ASStackLayoutSpec(direction: .horizontal,
                                               spacing: 8,
                                               justifyContent: .start,
                                               alignItems: .start,
                                               children: [lhsSpec, rhsSpec])
        let summarySpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), child: summaryRowSpec)

        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.style.preferredSize = constrainedSize.max
        pageSpec.children = [headerSpec, summarySpec]

        print(pageSpec.asciiArtString())
        return pageSpec
    }

}
