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
import PromiseKit
import PMKAlamofire

// mainly a copy of XResultsTableNode
// TODO: factor out commonality
class XDetailsNode: ASCellNode {
    
    //MARK: - Properties
    
    private let record: MBRecord
    private let itemIndex: Int
    private let totalItems: Int
    private let searchParameters: SearchParameters?

    private let pageHeader: ASDisplayNode
    private let pageHeaderText: ASTextNode

    private let titleNode: ASTextNode
    private let spacerNode: ASDisplayNode
    private let authorNode: ASTextNode
    private let formatNode: ASTextNode
    private let publicationNode: ASTextNode
    private let imageNode: ASNetworkImageNode
    
    private let copySummaryNode: ASTextNode
    private let placeHoldButton: ASButtonNode
    private let copyInfoButton: ASButtonNode
    
    //MARK: - Lifecycle
    
    init(record: MBRecord, index: Int, of totalItems: Int, searchParameters: SearchParameters?) {
        self.record = record
        self.itemIndex = index
        self.totalItems = totalItems
        self.searchParameters = searchParameters

        pageHeader = ASDisplayNode()
        pageHeaderText = ASTextNode()
        titleNode = ASTextNode()
        spacerNode = ASDisplayNode()
        authorNode = ASTextNode()
        formatNode = ASTextNode()
        publicationNode = ASTextNode()
        imageNode = ASNetworkImageNode()
        
        copySummaryNode = ASTextNode()
        placeHoldButton = ASButtonNode()
        copyInfoButton = ASButtonNode()

        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    override func didEnterPreloadState() {
        super.didEnterPreloadState()
        print("xxx XDetailsNode.didEnterPreloadState \(itemIndex) \(record.title)")
        guard let _ = App.account?.authtoken,
            let _ = App.account?.userID else
        {
            return
        }
        
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTree())
        promises.append(SearchService.fetchCopyStatusAll())
        
        let orgID = Organization.find(byShortName: searchParameters?.organizationShortName)?.id ?? Organization.consortiumOrgID
        let promise = SearchService.fetchCopyCounts(orgID: orgID, recordID: record.id)
        let done_promise = promise.done { array in
            self.record.copyCounts = CopyCounts.makeArray(fromArray: array)
        }
        promises.append(done_promise)
        
        firstly {
            when(fulfilled: promises)
        }.done {
            self.setupCopySummary()
        }.catch { error in
            self.viewController?.presentGatewayAlert(forError: error)
        }
    }

    //MARK: - Setup

    private func setupNodes() {
        self.setupPageHeader()
        self.setupTitle(titleNode, str: record.title, ofSize: 18)
        self.setupSubtitle(authorNode, str: record.author, ofSize: 16)
        self.setupSubtitle(formatNode, str: record.format, ofSize: 16)
        self.setupSubtitle(publicationNode, str: record.pubinfo, ofSize: 14)
        self.setupImageNode()
        self.setupSpacerNode()
        
        setupCopySummary()
        setupButtons()
    }
    
    private func setupPageHeader() {
        let naturalNumber = itemIndex + 1
        let str = "Showing Item \(naturalNumber) of \(totalItems)"
        pageHeaderText.attributedText = Style.makeTableHeaderString(str)
        pageHeader.backgroundColor = App.theme.tableHeaderBackground
    }

    private func setupTitle(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
        textNode.attributedText = Style.makeTitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 2
        textNode.truncationMode = .byWordWrapping
    }
    
    private func setupSubtitle(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
        textNode.attributedText = Style.makeSubtitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 1
        textNode.truncationMode = .byTruncatingTail
    }
    
    private func setupCopySummary() {
        var str = ""
        if let copyCounts = record.copyCounts,
            let copyCount = copyCounts.last,
            let orgName = Organization.find(byId: copyCount.orgID)?.name
        {
            str = "\(copyCount.available) of \(copyCount.count) copies available at \(orgName)"
        }
        copySummaryNode.attributedText = Style.makeString(str, ofSize: 16)
    }
    
    private func setupButtons() {
        placeHoldButton.setTitle("Place Hold", with: UIFont.systemFont(ofSize: 15), with: .white, for: .normal)
        Style.styleButton(asInverse: placeHoldButton)
        copyInfoButton.setTitle("Copy Info", with: UIFont.systemFont(ofSize: 15), with: .white, for: .normal)
        Style.styleButton(asInverse: copyInfoButton)
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

        self.addSubnode(copySummaryNode)
        self.addSubnode(placeHoldButton)
        self.addSubnode(copyInfoButton)
    }
    
    //MARK: - Layout
    
    override func layout() {
        super.layout()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // header row

        //pageHeader.style.preferredLayoutSize = ASLayoutSize(width: ASDimensionMake("100%"), height: ASDimensionMake(35))
        pageHeaderText.style.alignSelf = .center
        let header = pageHeaderText

        // summary row

        let imageWidth = 100.0
        let imageHeight = imageWidth * 1.6
        
        let lhsSpec = ASStackLayoutSpec.vertical()
        lhsSpec.spacing = 8.0
        lhsSpec.alignItems = .start
        lhsSpec.style.flexGrow = 1.0
        lhsSpec.style.flexShrink = 1.0
        lhsSpec.children = [titleNode, authorNode, formatNode, publicationNode]

        imageNode.style.preferredSize = CGSize(width: imageWidth, height: imageHeight)

        let rhsSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [imageNode])
        
        let summary = ASStackLayoutSpec(direction: .horizontal,
                                        spacing: 8,
                                        justifyContent: .start,
                                        alignItems: .start,
                                        children: [lhsSpec, rhsSpec])

        // copy summary row
        
        let copySummary = ASWrapperLayoutSpec(layoutElement: copySummaryNode)
        
        // button row
        
        let buttonRow = ASStackLayoutSpec.horizontal()
        buttonRow.spacing = 8
        placeHoldButton.style.flexGrow = 1.0
        copyInfoButton.style.flexGrow = 1.0
        buttonRow.children = [placeHoldButton, copyInfoButton]
        
        // page

        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 8
        pageSpec.style.preferredSize = constrainedSize.max
        pageSpec.children = [header, summary, copySummary, buttonRow]
        print(pageSpec.asciiArtString())
        
        let page = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), child: pageSpec)

        return page
    }

}
