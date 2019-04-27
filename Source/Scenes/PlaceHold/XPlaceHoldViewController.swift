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
    let emailSwitch = ASDisplayNode { () -> UIView in
        return UISwitch()
    }
    let phoneLabel = ASTextNode()
    let phoneSwitch = ASDisplayNode { () -> UIView in
        return UISwitch()
    }
    let phoneNode = ASDisplayNode { () -> UIView in
        return UITextField()
    }
    let smsLabel = ASTextNode()
    let smsSwitch = ASDisplayNode { () -> UIView in
        return UISwitch()
    }
    let smsNode = ASDisplayNode { () -> UIView in
        return UITextField()
    }
    let carrierLabel = ASTextNode()
    let carrierNode = ASButtonNode()
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
        
        setupPickupRow()
        setupEmailRow()
        setupPhoneRow()
        setupSmsRow()
        setupCarrierRow()
        
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
    
    func setupPickupRow() {
        pickupLabel.attributedText = Style.makeString("Pickup location:")
        Style.styleButton(asInverse: pickupNode)
    }

    func setupEmailRow() {
        emailLabel.attributedText = Style.makeString("Email notification:")
    }
    
    func setupPhoneRow() {
        phoneLabel.attributedText = Style.makeString("Phone notification:")
        guard let view = phoneNode.view as? UITextField else { return }
        view.placeholder = "Phone number"
        view.keyboardType = .phonePad
        view.borderStyle = .roundedRect
        view.delegate = self
    }

    func setupSmsRow() {
        smsLabel.attributedText = Style.makeString("SMS notification:")
        guard let view = smsNode.view as? UITextField else { return }
        view.placeholder = "Phone number"
        view.keyboardType = .phonePad
        view.borderStyle = .roundedRect
        view.delegate = self
    }
    
    func setupCarrierRow() {
        carrierLabel.attributedText = Style.makeString("SMS carrier:")
        Style.styleButton(asInverse: carrierNode)
    }

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

        // summary
        let summarySpec = ASStackLayoutSpec.vertical()
        summarySpec.children = [titleNode, authorNode, formatNode]
        
        // calculate size of widest label, so we can give them all the same width
        let label = App.config.enableHoldPhoneNotification ? phoneLabel : emailLabel
        let labelWidth = label.frame(forTextRange: NSMakeRange(0, label.attributedText?.length ?? 18)).size.width
        let labelMinWidth = ASDimensionMake(labelWidth)

        // shared dimensions
        // TIP: set preferredSize on a wrapped UIView or it ends up being (0,0)
        let switchPreferredSize = CGSize(width: 51, height: 31) // from IB
        let rowMinHeight = ASDimensionMake(switchPreferredSize.height)
        let spacing: CGFloat = 4
        let textFieldPreferredSize = CGSize(width: 217, height: 31) // from IB

        // pickup row
        pickupLabel.style.minWidth = labelMinWidth
        pickupNode.style.flexGrow = 1
        let pickupRowSpec = ASStackLayoutSpec.horizontal()
        pickupRowSpec.alignItems = .center
        pickupRowSpec.children = [pickupLabel, pickupNode]
        pickupRowSpec.spacing = spacing
        pickupRowSpec.style.spacingBefore = 28
        pickupRowSpec.style.minHeight = rowMinHeight

        // email row
        emailLabel.style.minWidth = labelMinWidth
        emailSwitch.style.preferredSize = switchPreferredSize
        let emailRowSpec = ASStackLayoutSpec.horizontal()
        emailRowSpec.alignItems = .center
        emailRowSpec.children = [emailLabel, emailSwitch]
        emailRowSpec.spacing = spacing

        // phone row
        phoneLabel.style.minWidth = labelMinWidth
        phoneSwitch.style.preferredSize = switchPreferredSize
        phoneNode.style.flexGrow = 1
        phoneNode.style.flexShrink = 1
        phoneNode.style.preferredSize = textFieldPreferredSize
        let phoneRowSpec = ASStackLayoutSpec.horizontal()
        phoneRowSpec.alignItems = .center
        phoneRowSpec.children = [phoneLabel, phoneSwitch, phoneNode]
        phoneRowSpec.spacing = spacing

        // sms row
        smsLabel.style.minWidth = labelMinWidth
        smsSwitch.style.preferredSize = switchPreferredSize
        smsNode.style.flexGrow = 1
        smsNode.style.flexShrink = 1
        smsNode.style.preferredSize = textFieldPreferredSize
        let smsRowSpec = ASStackLayoutSpec.horizontal()
        smsRowSpec.alignItems = .center
        smsRowSpec.children = [smsLabel, smsSwitch, smsNode]
        smsRowSpec.spacing = spacing
        smsRowSpec.style.minHeight = rowMinHeight

        // sms row2
        carrierLabel.style.minWidth = labelMinWidth
        carrierNode.style.flexGrow = 1
        let carrierRowSpec = ASStackLayoutSpec.horizontal()
        carrierRowSpec.alignItems = .center
        carrierRowSpec.children = [carrierLabel, carrierNode]
        carrierRowSpec.spacing = spacing
        carrierRowSpec.style.minHeight = rowMinHeight

        // page
        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 4
        pageSpec.alignItems = .stretch
        pageSpec.children = [summarySpec, pickupRowSpec, emailRowSpec]
        if App.config.enableHoldPhoneNotification {
            pageSpec.children?.append(phoneRowSpec)
        }
        pageSpec.children?.append(smsRowSpec)
        pageSpec.children?.append(carrierRowSpec)

        // inset entire page
        let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 4), child: pageSpec)
        print(spec.asciiArtString())
        return spec
     }
}

extension XPlaceHoldViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
}
