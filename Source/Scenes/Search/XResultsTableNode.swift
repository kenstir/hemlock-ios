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
    
    private let record: MBRecord
    
    private let titleNode = ASTextNode()
    private let spacerNode = ASDisplayNode()
    private let authorNode = ASTextNode()
    private let formatNode = ASTextNode()
    private let imageNode = ASNetworkImageNode()
    private var disclosureNode = XUtils.makeDisclosureNode()
    private let separatorNode = ASDisplayNode()
    
    //MARK: - Lifecycle
    
    init(record: MBRecord) {
        self.record = record

        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    //MARK: - Setup
    
    private func setupNodes() {
        self.setupTitleNode()
        self.setupAuthorNode()
        self.setupFormatNode()
        self.setupImageNode()
        self.setupSeparatorNode()
        self.setupSpacerNode()
    }
    
    private func setupTitleNode() {
        self.titleNode.attributedText = NSAttributedString(string: record.title, attributes: self.titleTextAttributes())
        self.titleNode.maximumNumberOfLines = 2
        self.titleNode.truncationMode = .byWordWrapping
    }
    
    private var titleTextAttributes = {
        return [NSAttributedString.Key.foregroundColor: Style.labelColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
    }
    
    private func setupAuthorNode() {
        self.authorNode.attributedText = NSAttributedString(string: record.author, attributes: self.authorTextAttributes())
        self.authorNode.maximumNumberOfLines = 1
        self.authorNode.truncationMode = .byTruncatingTail
    }
    
    private var authorTextAttributes = {
        return [NSAttributedString.Key.foregroundColor: Style.secondaryLabelColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
    }
    
    private func setupFormatNode() {
        self.formatNode.attributedText = NSAttributedString(string: record.iconFormatLabel, attributes: self.formatTextAttributes())
        self.formatNode.maximumNumberOfLines = 1
        self.formatNode.truncationMode = .byTruncatingTail
    }
    
    private var formatTextAttributes = {
        return [NSAttributedString.Key.foregroundColor: Style.secondaryLabelColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
    }
    
    private func setupImageNode() {
        let url = App.config.url + "/opac/extras/ac/jacket/medium/r/" + String(record.id)
        self.imageNode.contentMode = .scaleAspectFit 
        self.imageNode.url = URL(string: url)
    }

    private func setupSeparatorNode() {
        self.separatorNode.backgroundColor = Style.separatorColor
    }
    
    private func setupSpacerNode() {
        //self.spacerNode.backgroundColor = UIColor.red
    }
    
    //MARK: - Build node hierarchy
    
    private func buildNodeHierarchy() {
        self.addSubnode(titleNode)
        self.addSubnode(spacerNode)
        self.addSubnode(authorNode)
        self.addSubnode(formatNode)
        self.addSubnode(imageNode)
        self.addSubnode(disclosureNode)
        self.addSubnode(separatorNode)
    }
    
    //MARK: - Layout
    
    override func layout() {
        super.layout()
        let separatorHeight = 1 / UIScreen.main.scale
        self.separatorNode.frame = CGRect(x: 0.0, y: 0.0, width: self.calculatedSize.width, height: separatorHeight)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let imageWidth = 50.0
        let imageHeight = imageWidth * 1.6
        
        let lhsSpec = ASStackLayoutSpec.vertical()
        lhsSpec.style.flexShrink = 1.0
        lhsSpec.style.flexGrow = 1.0
        lhsSpec.style.preferredSize = CGSize(width: 0, height: imageHeight)
        spacerNode.style.flexShrink = 1.0
        spacerNode.style.flexGrow = 1.0
        lhsSpec.children = [titleNode, spacerNode, authorNode, formatNode]
        
        imageNode.style.preferredSize = CGSize(width: imageWidth, height: imageHeight)
        disclosureNode.style.preferredSize = CGSize(width: 27, height: 27)

        let rhsSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [imageNode, disclosureNode])
        
        let rowSpec = ASStackLayoutSpec(direction: .horizontal,
                                        spacing: 8,
                                        justifyContent: .start,
                                        alignItems: .center,
                                        children: [lhsSpec, rhsSpec])
        
        let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 4.0), child: rowSpec)
        //print(spec.asciiArtString())
        return spec
    }

}
