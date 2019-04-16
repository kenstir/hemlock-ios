//
//  XPlaceHoldViewController.swift
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

class XPlaceHoldViewController: ASViewController<ASDisplayNode> {
    
    //MARK: - Properties

    let record: MBRecord
    let formats = Format.getSpinnerLabels()
    var orgLabels: [String] = []
    var carrierLabels: [String] = []
    var selectedOrgName = ""
    var selectedCarrierName = ""
    var startOfFetch = Date()

    weak var activityIndicator: UIActivityIndicatorView!

    let containerNode = ASDisplayNode()
    let scrollNode = ASScrollNode()

    let titleNode = ASTextNode()
    let authorNode = ASTextNode()
    let formatNode = ASTextNode()
    let spacerNode = ASDisplayNode()
    let pickupLabel = ASTextNode()
    let pickupNode = ASButtonNode()
    let emailLabel = ASTextNode()
    let emailSwitch = ASDisplayNode()
    let emailNode = ASTextNode()
    let smsLabel = ASTextNode()
    let smsSwitch = ASDisplayNode()
    let smsNode = ASTextNode()
    let carrierLabel = ASTextNode()
    let carrierNode = ASTextNode()
    let placeHoldButton = ASButtonNode()

    //MARK: - Lifecycle
    
    init(record: MBRecord) {
        self.record = record

        super.init(node: containerNode)
        self.title = "Place Hold"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Setup
    
    func setupNodes() {
        Style.setupTitle(titleNode, str: record.title)
        Style.setupSubtitle(authorNode, str: record.author)
        Style.setupSubtitle(formatNode, str: record.format)
        
        pickupLabel.attributedText = Style.makeString("Pickup location:")
        Style.styleButton(asInverse: pickupNode)
        
        emailLabel.attributedText = Style.makeString("Email notification:")
        emailSwitch
        
        setupContainerNode()
        setupScrollNode()
    }
    
    func buildNodeHierarchy() {
    }

    //MARK: - Lifecycle
    
    // NB: viewDidLoad on an ASViewController gets called during construction,
    // before there is any UI.  Do not fetchData here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        setupNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Set isTranslucent=false else scrollNode
        // allows text to scroll underneath the nav bar
        navigationController?.navigationBar.isTranslucent = false
    }

    //MARK: - Layout
    
//    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
//        return ASWrapperLayoutSpec(layoutElement: self.scrollNode)
//    }

    func setupContainerNode() {
        containerNode.automaticallyManagesSubnodes = true
        containerNode.layoutSpecBlock = { node, constrainedSize in
            return ASWrapperLayoutSpec(layoutElement: self.scrollNode)
        }
    }
    
    func setupScrollNode() {
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = true
        scrollNode.layoutSpecBlock = { node, constrainedSize in
            return self.pageLayoutSpec(constrainedSize)
        }
    }

    func pageLayoutSpec(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {

        let summarySpec = ASStackLayoutSpec.vertical()
        summarySpec.children = [titleNode, authorNode, formatNode]
        
        let labelPreferredSize = CGSize(width: 128, height: 16)

        pickupLabel.style.preferredSize = labelPreferredSize
        let pickupRowSpec = ASStackLayoutSpec.horizontal()
        pickupRowSpec.style.flexGrow = 1.0
        pickupRowSpec.style.flexShrink = 1.0
        pickupRowSpec.children = [pickupLabel, pickupNode]
        
        emailLabel.style.preferredSize = labelPreferredSize
        let emailRowSpec = ASStackLayoutSpec.horizontal()
        emailRowSpec.style.flexGrow = 1.0
        emailRowSpec.style.flexShrink = 1.0
        emailRowSpec.children = [emailLabel, emailSwitch]

        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.children = [summarySpec, pickupRowSpec, emailRowSpec]

        let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 4.0), child: pageSpec)
        print(spec.asciiArtString())
        return spec
     }
}

