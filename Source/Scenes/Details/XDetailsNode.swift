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

// TODO: factor out common features of XResultsTableNode
class XDetailsNode: ASCellNode {
    
    //MARK: - Properties
    
    private let record: MBRecord
    private let itemIndex: Int
    private let totalItems: Int
    private let displayOptions: RecordDisplayOptions

    private let pageHeader = ASDisplayNode()
    private let pageHeaderText = ASTextNode()

    private let titleNode = ASTextNode()
    private let authorNode = ASTextNode()
    private let formatNode = ASTextNode()
    private let publicationNode = ASTextNode()
    private let imageNode = ASNetworkImageNode()
    
    private let copySummaryNode = ASTextNode()
    private let actionButton = ASButtonNode()
    private let copyInfoButton = ASButtonNode()
    private let addToListButton = ASButtonNode()
    private let extrasButton = ASButtonNode()
    
    private let scrollNode = ASScrollNode()
    private let synopsisNode = ASTextNode()
    private let subjectLabel = ASTextNode()
    private let subjectNode = ASTextNode()
    private let isbnLabel = ASTextNode()
    private let isbnNode = ASTextNode()
    
    private var showExtrasButton: Bool { return App.config.detailsExtraLinkText != nil }

    //MARK: - Lifecycle
    
    init(record: MBRecord, index: Int, of totalItems: Int, displayOptions: RecordDisplayOptions) {
        self.record = record
        self.itemIndex = index
        self.totalItems = totalItems
        self.displayOptions = displayOptions

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
        
        // Fetch orgs and copy statuses
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTree())
        promises.append(PCRUDService.fetchCodedValueMaps())
        promises.append(SearchService.fetchCopyStatusAll())

        // Fetch copy counts if not online resource
        if !App.behavior.isOnlineResource(record: record) {
            let orgID = Organization.find(byShortName: displayOptions.orgShortName)?.id ?? Organization.consortiumOrgID
            let promise = SearchService.fetchCopyCount(orgID: orgID, recordID: record.id)
            let done_promise = promise.done { array in
                self.record.copyCounts = CopyCount.makeArray(fromArray: array)
            }
            promises.append(done_promise)
        }
        
        // Fetch MARCXML record if needed
        if App.config.needMARCRecord {
            promises.insert(PCRUDService.fetchMARC(forRecord: record), at: 0)
        }
        
        // Fetch MRA if needed
        if record.attrs == nil {
            promises.append(PCRUDService.fetchMRA(forRecord: record))
        }

        firstly {
            when(fulfilled: promises)
        }.done {
            self.setupAsyncDataNodes()
        }.catch { error in
            self.viewController?.presentGatewayAlert(forError: error)
        }
    }

    @objc func copyInfoPressed(sender: Any) {
        let org = Organization.find(byShortName: self.displayOptions.orgShortName) ?? Organization.consortium()
        guard let myVC = self.closestViewController,
            let vc = UIStoryboard(name: "CopyInfo", bundle: nil).instantiateInitialViewController() as? CopyInfoViewController else { return }

        vc.org = org
        vc.record = record
        myVC.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func addToListPressed(sender: Any) {
        if App.account?.bookBagsEverLoaded == true {
            addToList()
            return
        }

        guard let vc = self.closestViewController else { return }
        guard let account = App.account,
              let authtoken = account.authtoken,
              let userID = account.userID else
        {
            vc.presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }

        // fetch the list of bookbags
        ActorService.fetchBookBags(account: account, authtoken: authtoken, userID: userID).done {
            self.addToList()
        }.catch { error in
            vc.presentGatewayAlert(forError: error, title: "Error fetching lists")
        }
    }

    func addToList() {
        guard let vc = self.closestViewController else { return }
        guard let bookBags = App.account?.bookBags,
              bookBags.count > 0 else
        {
            vc.navigationController?.view.makeToast("No lists")
            return
        }

        // Build an action sheet to display the options
        let alertController = UIAlertController(title: "Add to List", message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        for bookBag in bookBags {
            alertController.addAction(UIAlertAction(title: bookBag.name, style: .default) { action in
                self.addItem(toBookBag: bookBag)
            })
        }
//        alertController.addAction(UIAlertAction(title: "Add to New List", style: .default) { action in
//            vc.showAlert(title: "TODO", message: "create new")
//        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alertController.popoverPresentationController {
            let view: UIView = self.view
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        vc.present(alertController, animated: true)
    }
    
    func addItem(toBookBag bookBag: BookBag) {
        guard let authtoken = App.account?.authtoken else { return }
        guard let vc = self.closestViewController else { return }

        ActorService.addItemToBookBag(authtoken: authtoken, bookBagId: bookBag.id, recordId: record.id).done {
            vc.navigationController?.view.makeToast("Item added to list")
        }.catch { error in
            vc.presentGatewayAlert(forError: error)
        }
    }
    
    @objc func extrasPressed(sender: Any) {
        var url = App.config.url + "/eg/opac/record/" + String(record.id)
        if let q = App.config.detailsExtraLinkQuery {
            url += "?" + q
        }
        if let fragment = App.config.detailsExtraLinkFragment {
            url += "#" + fragment
        }
        guard let vc = self.closestViewController else { return }
        self.openOnlineLocation(vc: vc, href: url)
    }
    
    func openOnlineLocation(vc: UIViewController, href: String) {
        guard let url = URL(string: href) else {
            vc.showAlert(title: "Error parsing URL", message: "Unable to parse online location \(href)")
            return
        }
        UIApplication.shared.open(url)
    }
    
    @objc func onlineAccessPressed(sender: Any) {
        let links = App.behavior.onlineLocations(record: record, forSearchOrg: displayOptions.orgShortName)
        guard links.count > 0, let vc = self.closestViewController else { return }
        
        // If there's only one link, open it without ceremony
        if links.count == 1 && !App.config.alwaysPopupOnlineLinks {
            openOnlineLocation(vc: vc, href: links[0].href)
            return
        }

        // Build an action sheet to present the links
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        for link in links {
            alertController.addAction(UIAlertAction(title: link.text, style: .default) { action in
                self.openOnlineLocation(vc: vc, href: link.href)
            })
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            let view = self.view
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        vc.present(alertController, animated: true)
    }

    @objc func placeHoldPressed(sender: Any) {
        guard let myVC = self.closestViewController else { return }
        
        let vc = XPlaceHoldViewController(record: record)
        myVC.navigationController?.pushViewController(vc, animated: true)
    }

    //MARK: - Setup

    private func setupNodes() {
        setupPageHeader()
        Style.setupTitle(titleNode, str: record.title, ofSize: Style.titleSize, maxNumLines: 5)
        Style.setupSubtitle(authorNode, str: record.author, ofSize: Style.subtitleSize)
        Style.setupSubtitle(publicationNode, str: record.pubinfo, ofSize: Style.subheadSize)
        setupImageNode()

        setupAsyncDataNodes()
        
        setupScrollNode()
        
        Style.setupSynopsisText(synopsisNode, str: record.synopsis, ofSize: Style.bodySize)
        Style.setupSubtitle(subjectLabel, str: "Subject:", ofSize: Style.subheadSize)
        Style.setupMultilineText(subjectNode, str: record.subject, ofSize: Style.subheadSize)
        Style.setupSubtitle(isbnLabel, str: "ISBN:", ofSize: Style.subheadSize)
        Style.setupMultilineText(isbnNode, str: record.isbn, ofSize: Style.subheadSize)
    }
    
    private func setupPageHeader() {
        let naturalNumber = itemIndex + 1
        let str = "Showing Item \(naturalNumber) of \(totalItems)"
        pageHeaderText.attributedText = Style.makeTableHeaderString(str, size: Style.calloutSize)
        pageHeader.backgroundColor = Style.systemGroupedBackground
    }
    
    private func setupAsyncDataNodes() {
        setupFormat()
        setupCopySummary()
        setupButtons()
    }
    
    private func setupFormat() {
        Style.setupSubtitle(formatNode, str: record.iconFormatLabel, ofSize: Style.calloutSize)
    }

    private func setupCopySummary() {
        var str = ""
        if App.behavior.isOnlineResource(record: record) {
            if let onlineLocation = record.firstOnlineLocationInMVR,
                let host = URL(string: onlineLocation)?.host,
                App.config.showOnlineAccessHostname
            {
                str = host
            }
            copySummaryNode.attributedText = Style.makeSubtitleString(str, ofSize: Style.subheadSize)
        } else {
            if let copyCounts = record.copyCounts,
                let copyCount = copyCounts.last,
                let orgName = Organization.find(byId: copyCount.orgID)?.name
            {
                str = "\(copyCount.available) of \(copyCount.count) copies available at \(orgName)"
            }
            copySummaryNode.attributedText = Style.makeString(str, ofSize: Style.calloutSize)
        }
    }
    
    private func setupButtons() {
        var actionButtonText: String
        let isOnlineResource = App.behavior.isOnlineResource(record: record)

        // This function will be called more than once, clear targets first
        actionButton.removeTarget(self, action: nil, forControlEvents: .allEvents)
        copyInfoButton.removeTarget(self, action: nil, forControlEvents: .allEvents)
        addToListButton.removeTarget(self, action: nil, forControlEvents: .allEvents)

        if isOnlineResource {
            actionButtonText = "Online Access"
            actionButton.addTarget(self, action: #selector(onlineAccessPressed(sender:)), forControlEvents: .touchUpInside)
            actionButton.isEnabled = (App.behavior.onlineLocations(record: record, forSearchOrg: displayOptions.orgShortName).count > 0)
        } else {
            actionButtonText = "Place Hold"
            actionButton.addTarget(self, action: #selector(placeHoldPressed(sender:)), forControlEvents: .touchUpInside)
            actionButton.isEnabled = displayOptions.enablePlaceHold
        }
        Style.styleButton(asInverse: actionButton, title: actionButtonText)

        if isOnlineResource {
            copyInfoButton.isEnabled = false
            copyInfoButton.isHidden = true
        } else {
            Style.styleButton(asOutline: copyInfoButton, title: "Copy Info")
            copyInfoButton.addTarget(self, action: #selector(copyInfoPressed(sender:)), forControlEvents: .touchUpInside)
        }
        
        Style.styleButton(asOutline: addToListButton, title: "Add to List")
        addToListButton.addTarget(self, action: #selector(addToListPressed(sender:)), forControlEvents: .touchUpInside)

        if let title = App.config.detailsExtraLinkText,
           let _ = App.config.detailsExtraLinkFragment
        {
            Style.styleButton(asPlain: extrasButton, title: title)
            extrasButton.addTarget(self, action: #selector(extrasPressed(sender:)), forControlEvents: .touchUpInside)
        }
    }

    private func setupImageNode() {
        let url = App.config.url + "/opac/extras/ac/jacket/medium/r/" + String(record.id)
        self.imageNode.contentMode = .scaleAspectFit 
        self.imageNode.url = URL(string: url)
    }
    
    private func buildNodeHierarchy() {
        self.addSubnode(scrollNode)
    }
    
    //MARK: - Layout
    //
    // Zen of this layout:
    // * DetailsNode has scrollNode as its only child
    // * scrollNode children are all automatically managed
    // * scrollNode.layoutSpecBlock is closure around pageLayoutSpec
    //
    // This is all to workaround a scrollNode issue in the manner described in
    // https://github.com/TextureGroup/Texture/issues/774
    
    override func layout() {
        super.layout()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASWrapperLayoutSpec(layoutElement: self.scrollNode)
    }
    
    func setupScrollNode() {
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = true
        scrollNode.layoutSpecBlock = { node, constrainedSize in
            return self.pageLayoutSpec(constrainedSize)
        }
    }

    func pageLayoutSpec(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // header row

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
        buttonsSpec.lineSpacing = 8
        buttonsSpec.flexWrap = .wrap
        actionButton.style.flexGrow = 1.0
        copyInfoButton.style.flexGrow = 1.0
        addToListButton.style.flexGrow = 1.0
        buttonsSpec.children = [actionButton, copyInfoButton, addToListButton]
        let buttonRow = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0), child: buttonsSpec)

        // subject
        
        let subject = ASStackLayoutSpec.horizontal()
        if !record.subject.isEmpty {
            subjectLabel.style.preferredSize = CGSize(width: 64, height: Style.calloutSize)
            subject.children = [subjectLabel, subjectNode]
        }

        // isbn
        
        let isbn = ASStackLayoutSpec.horizontal()
        if !record.isbn.isEmpty {
            isbnLabel.style.preferredSize = CGSize(width: 64, height: Style.calloutSize)
            isbn.children = [isbnLabel, isbnNode]
        }

        // page

        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 8
        pageSpec.children = [header, summary, copySummary,
                             buttonRow, synopsisNode]
        if showExtrasButton {
            pageSpec.children?.append(extrasButton)
        }
        pageSpec.children?.append(contentsOf: [subject, isbn])
        print(pageSpec.asciiArtString())
        
        let page = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), child: pageSpec)
        
        return page
    }

}
