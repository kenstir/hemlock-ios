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
    private let displayOptions: RecordDisplayOptions

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
    
    private let synopsisNode = ASTextNode()
    private let subjectLabel = ASTextNode()
    private let subjectNode = ASTextNode()
    private let isbnLabel = ASTextNode()
    private let isbnNode = ASTextNode()
    
    //MARK: - Lifecycle
    
    init(record: MBRecord, index: Int, of totalItems: Int, displayOptions: RecordDisplayOptions) {
        self.record = record
        self.itemIndex = index
        self.totalItems = totalItems
        self.displayOptions = displayOptions

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

        guard let _ = App.account?.authtoken,
            let _ = App.account?.userID else
        {
            return
        }
        
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgs())
        promises.append(SearchService.fetchCopyStatusAll())
        
        let orgID = Organization.find(byShortName: displayOptions.orgShortName)?.id ?? Organization.consortiumOrgID
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

    @objc func copyInfoPressed(sender: Any) {
        let org = Organization.find(byShortName: self.displayOptions.orgShortName) ?? Organization.consortium()
        guard let myVC = self.closestViewController,
            let vc = UIStoryboard(name: "CopyInfo", bundle: nil).instantiateInitialViewController(),
            let copyInfoVC = vc as? CopyInfoViewController else { return }

        copyInfoVC.org = org
        copyInfoVC.record = record
        myVC.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func placeHoldPressed(sender: Any) {
        guard let myVC = self.closestViewController,
            let vc = UIStoryboard(name: "PlaceHolds", bundle: nil).instantiateInitialViewController(),
            let placeHoldsVC = vc as? PlaceHoldsViewController else { return }

        placeHoldsVC.record = record
        myVC.navigationController?.pushViewController(vc, animated: true)
    }

    //MARK: - Setup

    private func setupNodes() {
        setupPageHeader()
        setupTitle(titleNode, str: record.title, ofSize: 18)
        setupSubtitle(authorNode, str: record.author, ofSize: 16)
        setupSubtitle(formatNode, str: record.format, ofSize: 16)
        setupSubtitle(publicationNode, str: record.pubinfo, ofSize: 14)
        setupImageNode()
        setupSpacerNode()
        
        setupCopySummary()
        setupButtons()
        
        setupMultilineText(synopsisNode, str: record.synopsis, ofSize: 14)
        setupSubtitle(subjectLabel, str: "Subject:", ofSize: 14)
        setupMultilineText(subjectNode, str: record.subject, ofSize: 14)
        setupSubtitle(isbnLabel, str: "ISBN:", ofSize: 14)
        setupMultilineText(isbnNode, str: record.isbn, ofSize: 14)
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
    
    private func setupMultilineText(_ textNode: ASTextNode, str: String, ofSize size: CGFloat) {
        textNode.attributedText = Style.makeSubtitleString(str, ofSize: size)
        textNode.maximumNumberOfLines = 0
//        textNode.truncationMode = .byTruncatingTail
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
        let title = "Place Hold"
        let font = UIFont.systemFont(ofSize: 15)
        Style.styleButton(asInverse: placeHoldButton)
        placeHoldButton.setTitle(title, with: font, with: .white, for: .normal)
        placeHoldButton.setTitle(title, with: font, with: .gray, for: .disabled)
        placeHoldButton.setTitle(title, with: font, with: .gray, for: .highlighted)
        placeHoldButton.addTarget(self, action: #selector(placeHoldPressed(sender:)), forControlEvents: .touchUpInside)
        placeHoldButton.isEnabled = displayOptions.enablePlaceHold

        let t2 = "Copy Info"
        copyInfoButton.setTitle(t2, with: font, with: .white, for: .normal)
        copyInfoButton.setTitle(t2, with: font, with: .gray, for: .disabled)
        copyInfoButton.setTitle(t2, with: font, with: .gray, for: .highlighted)
        Style.styleButton(asInverse: copyInfoButton)
        copyInfoButton.addTarget(self, action: #selector(copyInfoPressed(sender:)), forControlEvents: .touchUpInside)
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
        
        self.addSubnode(synopsisNode)
        self.addSubnode(subjectLabel)
        self.addSubnode(subjectNode)
        self.addSubnode(isbnLabel)
        self.addSubnode(isbnNode)
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
        
        let buttonsSpec = ASStackLayoutSpec.horizontal()
        buttonsSpec.spacing = 8
        placeHoldButton.style.flexGrow = 1.0
        copyInfoButton.style.flexGrow = 1.0
        buttonsSpec.children = [placeHoldButton, copyInfoButton]
        let buttonRow = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0), child: buttonsSpec)
        
        // subject
        
        let subject = ASStackLayoutSpec.horizontal()
//        subject.style.flexGrow = 1.0
        subjectLabel.style.preferredSize = CGSize(width: 64, height: 16)
        subject.children = [subjectLabel, subjectNode]
        
        // isbn
        
        let isbn = ASStackLayoutSpec.horizontal()
//        isbn.style.flexGrow = 1.0
        isbnLabel.style.preferredSize = CGSize(width: 64, height: 16)
        isbn.children = [isbnLabel, isbnNode]

        // page

        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 8
        pageSpec.style.preferredSize = constrainedSize.max
        pageSpec.children = [header, summary, copySummary,
                             buttonRow, synopsisNode, subject, isbn]
        print(pageSpec.asciiArtString())
        
        let page = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), child: pageSpec)

        return page
    }

}
